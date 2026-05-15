import Foundation

struct RealtimeTokenResponse: Decodable {
    struct ClientSecret: Decodable {
        let value: String
        let expiresAt: Int?

        enum CodingKeys: String, CodingKey {
            case value
            case expiresAt = "expires_at"
        }
    }

    let value: String?
    let clientSecret: ClientSecret?
    let callEndpoint: URL?
    let model: String?

    enum CodingKeys: String, CodingKey {
        case value
        case clientSecret = "client_secret"
        case callEndpoint = "call_endpoint"
        case model
    }

    var token: String? {
        value ?? clientSecret?.value
    }
}

final class BackendClient {
    private let baseURL: URL
    private let urlSession: URLSession

    init(
        baseURL: URL = URL(string: Bundle.main.object(forInfoDictionaryKey: "SAMANTHA_SUPABASE_FUNCTIONS_URL") as? String ?? "https://bkihgttwlfddnykagyvz.supabase.co/functions/v1")!,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    func realtimeToken(entitlement: EntitlementPayload, outputLanguage: AppLanguage) async throws -> RealtimeTokenResponse {
        let url = baseURL.appending(path: "realtime-token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RealtimeTokenRequest(entitlement: entitlement, outputLanguage: outputLanguage.realtimeLabel))

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw BackendError.server(String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)")
        }
        return try JSONDecoder().decode(RealtimeTokenResponse.self, from: data)
    }
}

private struct RealtimeTokenRequest: Encodable {
    let entitlement: EntitlementPayload
    let outputLanguage: String
}

enum BackendError: LocalizedError {
    case invalidResponse
    case missingEntitlement
    case missingRealtimeToken
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server response was invalid."
        case .missingEntitlement: "Start the free trial to unlock real-time translation."
        case .missingRealtimeToken: "The server did not return a usable voice token."
        case .server(let message): message
        }
    }
}
