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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if case .error = state { return }
        state = .idle
    }

    private func startAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
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
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let socket = URLSession.shared.webSocketTask(with: request)
        webSocket = socket
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

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                let payload = try Self.realtimePCMBase64(from: buffer)
                guard !payload.isEmpty else { return }
                Task { try? await self.sendJSON(["type": "input_audio_buffer.append", "audio": payload]) }
            } catch {
                Task { @MainActor in self.fail(error.localizedDescription) }
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

    private static func realtimePCMBase64(from buffer: AVAudioPCMBuffer) throws -> String {
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            throw AudioPipelineError.audioConverterUnavailable
        }
        let outputFrameCapacity = AVAudioFrameCount((Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate).rounded(.up)) + 16
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            throw AudioPipelineError.audioConverterUnavailable
        }

        let inputState = ConverterInputState(buffer)
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if inputState.wasConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputState.wasConsumed = true
            outStatus.pointee = .haveData
            return inputState.buffer
        }

        if let conversionError { throw conversionError }
        guard status != .error else { throw AudioPipelineError.audioConversionFailed }
        guard outputBuffer.frameLength > 0 else { return "" }

        let audioBuffer = outputBuffer.audioBufferList.pointee.mBuffers
        guard let bytes = audioBuffer.mData else { return "" }
        return Data(bytes: bytes, count: Int(audioBuffer.mDataByteSize)).base64EncodedString()
    }

    private static func errorMessage(from event: [String: Any]) -> String {
        if let error = event["error"] as? [String: Any] {
            if let message = error["message"] as? String { return message }
            if let code = error["code"] as? String { return code }
        }
        return "The realtime voice session reported an error."
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

private final class ConverterInputState: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    var wasConsumed = false

    init(_ buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }
}
