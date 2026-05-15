import AVFoundation
import Foundation

@MainActor
final class TranslationSession: ObservableObject {
    enum State: Equatable {
        case idle
        case preparing
        case listening
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastTranscript = ""
    @Published private(set) var lastTranslation = ""

    private let audioEngine = AVAudioEngine()
    private let outputEngine = AVAudioEngine()
    private let outputPlayer = AVAudioPlayerNode()
    private let playbackFormat = AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 1)!
    private let socketWriter = RealtimeSocketWriter()
    private var webSocket: URLSessionWebSocketTask?
    private var messageTask: Task<Void, Never>?
    private var hasInputTap = false
    private weak var entitlementProvider: EntitlementStore?

    init() {
        outputEngine.attach(outputPlayer)
        outputEngine.connect(outputPlayer, to: outputEngine.mainMixerNode, format: playbackFormat)
    }

    func configure(entitlementProvider: EntitlementStore) async {
        self.entitlementProvider = entitlementProvider
    }

    func start(outputLanguage: AppLanguage) async {
        guard let entitlement = await entitlementProvider?.currentEntitlementPayload() else {
            state = .error(BackendError.missingEntitlement.localizedDescription)
            return
        }

        do {
            state = .preparing
            lastTranscript = ""
            lastTranslation = ""
            let tokenResponse = try await BackendClient().realtimeToken(entitlement: entitlement, outputLanguage: outputLanguage)
            guard let token = tokenResponse.token else { throw BackendError.missingRealtimeToken }
            try startAudioSession()
            try await connectRealtime(token: token, tokenResponse: tokenResponse, outputLanguage: outputLanguage)
            try startOutputPlayback()
            try startMicrophoneStreaming()
            state = .listening
        } catch {
            stop()
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        messageTask?.cancel()
        messageTask = nil
        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        audioEngine.stop()
        outputPlayer.stop()
        outputEngine.stop()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        let socketWriter = socketWriter
        Task { await socketWriter.clear() }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if case .error = state { return }
        state = .idle
    }

    private func startAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true)
    }

    private func startOutputPlayback() throws {
        outputPlayer.stop()
        outputEngine.reset()
        if !outputEngine.isRunning {
            try outputEngine.start()
        }
        outputPlayer.play()
    }

    private func connectRealtime(token: String, tokenResponse: RealtimeTokenResponse, outputLanguage: AppLanguage) async throws {
        let endpoint = tokenResponse.callEndpoint ?? URL(string: "wss://api.openai.com/v1/realtime")!
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw BackendError.invalidResponse
        }
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "model" }
        queryItems.append(URLQueryItem(name: "model", value: tokenResponse.model ?? "gpt-realtime"))
        components.queryItems = queryItems
        guard let url = components.url else { throw BackendError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let socket = URLSession.shared.webSocketTask(with: request)
        webSocket = socket
        await socketWriter.setSocket(WebSocketBox(socket))
        socket.resume()
        listenForMessages()

        let instructions = "Translate any detected speech into \(outputLanguage.realtimeLabel). Output only the translated speech. Do not store or summarize audio."
        try await sendJSON([
            "type": "session.update",
            "session": [
                "type": "realtime",
                "instructions": instructions,
                "output_modalities": ["audio"],
                "audio": [
                    "input": [
                        "format": ["type": "audio/pcm", "rate": 24000],
                        "turn_detection": [
                            "type": "server_vad",
                            "threshold": 0.45,
                            "prefix_padding_ms": 160,
                            "silence_duration_ms": 240,
                            "create_response": true,
                            "interrupt_response": true
                        ],
                        "transcription": ["model": "gpt-4o-mini-transcribe"]
                    ],
                    "output": [
                        "voice": "marin",
                        "format": ["type": "audio/pcm", "rate": 24000]
                    ]
                ]
            ]
        ])
    }

    private func startMicrophoneStreaming() throws {
        let input = audioEngine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.channelCount > 0 else { throw AudioPipelineError.microphoneUnavailable }

        if hasInputTap {
            input.removeTap(onBus: 0)
            hasInputTap = false
        }

        let socketWriter = socketWriter
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            do {
                let chunk = try Self.realtimeAudioChunk(from: buffer)
                guard !chunk.samples.isEmpty else { return }
                Task.detached(priority: .userInitiated) {
                    await socketWriter.sendAudioChunk(chunk)
                }
            } catch {
                Task { @MainActor in self?.fail(error.localizedDescription) }
            }
        }
        hasInputTap = true
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func listenForMessages() {
        messageTask?.cancel()
        messageTask = Task { [weak self] in
            guard let self else { return }
            while let socket = self.webSocket, !Task.isCancelled {
                do {
                    let message = try await socket.receive()
                    await self.handle(message: message)
                } catch {
                    await MainActor.run {
                        if case .listening = self.state {
                            self.state = .error(error.localizedDescription)
                        }
                    }
                    return
                }
            }
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message) async {
        guard case .string(let text) = message,
              let data = text.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["type"] as? String else { return }

        switch type {
        case "response.output_audio.delta", "response.audio.delta":
            if let delta = event["delta"] as? String { playAudioDelta(delta) }
        case "response.output_audio_transcript.delta", "response.audio_transcript.delta", "response.output_text.delta", "response.text.delta":
            if let delta = event["delta"] as? String { lastTranslation += delta }
        case "conversation.item.input_audio_transcription.completed", "input_audio_buffer.transcription.completed":
            if let transcript = event["transcript"] as? String { lastTranscript = transcript }
        case "input_audio_buffer.speech_started":
            lastTranscript = ""
            lastTranslation = ""
        case "error":
            fail(Self.errorMessage(from: event))
        default:
            break
        }
    }

    private func sendJSON(_ object: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        guard let text = String(data: data, encoding: .utf8) else { return }
        guard let webSocket else { throw BackendError.invalidResponse }
        try await webSocket.send(.string(text))
    }

    private func playAudioDelta(_ base64: String) {
        guard let data = Data(base64Encoded: base64) else { return }
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: playbackFormat, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }

        buffer.frameLength = AVAudioFrameCount(sampleCount)
        data.withUnsafeBytes { rawBuffer in
            guard let source = rawBuffer.bindMemory(to: Int16.self).baseAddress,
                  let channel = buffer.floatChannelData?[0] else { return }
            for index in 0..<sampleCount {
                let sample = Int16(littleEndian: source[index])
                channel[index] = max(-1, Float(sample) / Float(Int16.max))
            }
        }

        if !outputEngine.isRunning {
            try? outputEngine.start()
        }
        if !outputPlayer.isPlaying {
            outputPlayer.play()
        }
        outputPlayer.scheduleBuffer(buffer)
    }

    private func fail(_ message: String) {
        stop()
        state = .error(message)
    }

    nonisolated private static func realtimeAudioChunk(from buffer: AVAudioPCMBuffer) throws -> RealtimeAudioChunk {
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return RealtimeAudioChunk(samples: [], sampleRate: buffer.format.sampleRate) }
        let channelCount = max(1, Int(buffer.format.channelCount))
        var samples = Array(repeating: Float.zero, count: frameCount)

        if let floatChannels = buffer.floatChannelData {
            for frame in 0..<frameCount {
                var mixed = Float.zero
                for channel in 0..<channelCount {
                    mixed += floatChannels[channel][frame]
                }
                samples[frame] = mixed / Float(channelCount)
            }
        } else if let int16Channels = buffer.int16ChannelData {
            for frame in 0..<frameCount {
                var mixed = Float.zero
                for channel in 0..<channelCount {
                    mixed += Float(Int16(littleEndian: int16Channels[channel][frame])) / Float(Int16.max)
                }
                samples[frame] = mixed / Float(channelCount)
            }
        } else {
            throw AudioPipelineError.audioConversionFailed
        }

        return RealtimeAudioChunk(samples: samples, sampleRate: buffer.format.sampleRate)
    }

    private static func errorMessage(from event: [String: Any]) -> String {
        if let error = event["error"] as? [String: Any] {
            if let message = error["message"] as? String { return message }
            if let code = error["code"] as? String { return code }
        }
        return "The realtime voice session reported an error."
    }
}

private final class WebSocketBox: @unchecked Sendable {
    let task: URLSessionWebSocketTask

    init(_ task: URLSessionWebSocketTask) {
        self.task = task
    }
}

private struct RealtimeAudioChunk: Sendable {
    let samples: [Float]
    let sampleRate: Double
}

private actor RealtimeSocketWriter {
    private var socket: WebSocketBox?
    private var pendingChunks = 0

    func setSocket(_ socket: WebSocketBox) {
        self.socket = socket
    }

    func clear() {
        socket = nil
        pendingChunks = 0
    }

    func sendAudioChunk(_ chunk: RealtimeAudioChunk) async {
        pendingChunks += 1
        guard pendingChunks <= 10 else {
            pendingChunks -= 1
            return
        }
        defer { pendingChunks -= 1 }

        guard let payload = Self.pcm24kBase64(from: chunk), !payload.isEmpty else { return }
        try? await sendJSON(["type": "input_audio_buffer.append", "audio": payload])
    }

    func sendJSON(_ object: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        guard let text = String(data: data, encoding: .utf8) else { return }
        guard let socket else { throw BackendError.invalidResponse }
        try await socket.task.send(.string(text))
    }

    nonisolated private static func pcm24kBase64(from chunk: RealtimeAudioChunk) -> String? {
        guard chunk.sampleRate > 0, !chunk.samples.isEmpty else { return nil }
        let targetRate = 24_000.0
        let outputCount = max(1, Int((Double(chunk.samples.count) * targetRate / chunk.sampleRate).rounded(.down)))
        let step = chunk.sampleRate / targetRate
        var data = Data(capacity: outputCount * MemoryLayout<Int16>.size)

        for index in 0..<outputCount {
            let sourcePosition = Double(index) * step
            let lower = min(Int(sourcePosition), chunk.samples.count - 1)
            let upper = min(lower + 1, chunk.samples.count - 1)
            let fraction = Float(sourcePosition - Double(lower))
            let interpolated = chunk.samples[lower] + (chunk.samples[upper] - chunk.samples[lower]) * fraction
            let clipped = max(-1, min(1, interpolated))
            var sample = Int16(clipped * Float(Int16.max)).littleEndian
            withUnsafeBytes(of: &sample) { data.append(contentsOf: $0) }
        }

        return data.base64EncodedString()
    }
}

private enum AudioPipelineError: LocalizedError {
    case microphoneUnavailable
    case audioConverterUnavailable
    case audioConversionFailed

    var errorDescription: String? {
        switch self {
        case .microphoneUnavailable:
            "Microphone input is not available on this device."
        case .audioConverterUnavailable:
            "The microphone audio could not be prepared for realtime translation."
        case .audioConversionFailed:
            "The microphone audio conversion failed."
        }
    }
}
