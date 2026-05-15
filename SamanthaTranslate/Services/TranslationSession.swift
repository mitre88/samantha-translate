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
    private var webSocket: URLSessionWebSocketTask?
    private weak var entitlementProvider: EntitlementStore?

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
            let tokenResponse = try await BackendClient().realtimeToken(entitlement: entitlement, outputLanguage: outputLanguage)
            guard let token = tokenResponse.token else { throw BackendError.missingRealtimeToken }
            try await connectRealtime(token: token, outputLanguage: outputLanguage)
            try startMicrophoneStreaming()
            state = .listening
        } catch {
            stop()
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        if case .error = state { return }
        state = .idle
    }

    private func connectRealtime(token: String, outputLanguage: AppLanguage) async throws {
        var components = URLComponents(string: "wss://api.openai.com/v1/realtime")!
        components.queryItems = [URLQueryItem(name: "model", value: "gpt-realtime")]
        var request = URLRequest(url: components.url!)
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
                "modalities": ["audio", "text"],
                "audio": [
                    "input": [
                        "format": ["type": "audio/pcm", "rate": 24000],
                        "turn_detection": ["type": "server_vad"]
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
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let payload = Self.base64PCM16(buffer: buffer)
            Task { try? await self.sendJSON(["type": "input_audio_buffer.append", "audio": payload]) }
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func listenForMessages() {
        Task { [weak self] in
            guard let self else { return }
            while let socket = self.webSocket {
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

        await MainActor.run {
            if type.contains("input_audio_transcription") || type.contains("transcript") {
                if let transcript = event["transcript"] as? String { lastTranscript = transcript }
                if let delta = event["delta"] as? String { lastTranslation += delta }
            }
        }
    }

    private func sendJSON(_ object: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        guard let text = String(data: data, encoding: .utf8) else { return }
        try await webSocket?.send(.string(text))
    }

    private static func base64PCM16(buffer: AVAudioPCMBuffer) -> String {
        guard let channel = buffer.floatChannelData?[0] else { return "" }
        let frameLength = Int(buffer.frameLength)
        var data = Data(capacity: frameLength * 2)
        for index in 0..<frameLength {
            let sample = max(-1, min(1, channel[index]))
            var intSample = Int16(sample * Float(Int16.max)).littleEndian
            data.append(Data(bytes: &intSample, count: MemoryLayout<Int16>.size))
        }
        return data.base64EncodedString()
    }
}
