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

    private var realtimeClient: RealtimeWebRTCClient?
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
            lastTranscript = ""
            lastTranslation = ""

            let tokenResponse = try await BackendClient().realtimeToken(entitlement: entitlement, outputLanguage: outputLanguage)
            guard let token = tokenResponse.token else { throw BackendError.missingRealtimeToken }

            let client = RealtimeWebRTCClient()
            realtimeClient = client

            try await client.connect(
                token: token,
                endpoint: tokenResponse.webRTCEndpoint ?? URL(string: "https://api.openai.com/v1/realtime/translations/calls")!,
                outputLanguage: outputLanguage,
                onEvent: { [weak self] text in
                    self?.handle(eventText: text)
                },
                onFailure: { [weak self] message in
                    self?.fail(message)
                }
            )

            state = .listening
        } catch {
            stop()
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        realtimeClient?.disconnect()
        realtimeClient = nil
        if case .error = state { return }
        state = .idle
    }

    func updateOutputLanguage(_ outputLanguage: AppLanguage) {
        guard case .listening = state, let realtimeClient else { return }
        do {
            try realtimeClient.updateOutputLanguage(outputLanguage)
            lastTranscript = ""
            lastTranslation = ""
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func handle(eventText text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["type"] as? String else { return }

        switch type {
        case "session.created", "session.updated":
            break
        case "session.output_transcript.delta", "response.output_audio_transcript.delta", "response.audio_transcript.delta", "response.output_text.delta", "response.text.delta":
            if let delta = event["delta"] as? String { lastTranslation += delta }
        case "session.input_transcript.delta":
            if let delta = event["delta"] as? String { lastTranscript += delta }
        case "conversation.item.input_audio_transcription.completed", "input_audio_buffer.transcription.completed", "session.input_transcript.completed":
            if let transcript = event["transcript"] as? String { lastTranscript = transcript }
        case "input_audio_buffer.speech_started", "session.input_audio_buffer.speech_started":
            lastTranscript = ""
            lastTranslation = ""
        case "error":
            fail(Self.errorMessage(from: event))
        default:
            break
        }
    }

    private func fail(_ message: String) {
        stop()
        state = .error(message)
    }

    private static func errorMessage(from event: [String: Any]) -> String {
        if let error = event["error"] as? [String: Any] {
            if let message = error["message"] as? String { return message }
            if let code = error["code"] as? String { return code }
        }
        return "The realtime voice session reported an error."
    }
}
