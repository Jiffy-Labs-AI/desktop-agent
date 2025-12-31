import Foundation

struct Event: Codable {
    let type: String
    let source: String
    let metadata: [String: String]
    let tabId: Int?
    let sessionId: String?

    init(
        type: String,
        source: String = Constants.Sources.claudeDesktop,
        metadata: [String: String],
        tabId: Int? = nil,
        sessionId: String? = nil
    ) {
        self.type = type
        self.source = source
        self.metadata = metadata
        self.tabId = tabId
        self.sessionId = sessionId
    }
}

enum EventError: Error, LocalizedError {
    case notAuthenticated
    case sendFailed
    case invalidResponse
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .sendFailed:
            return "Failed to send event to server."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
