import Foundation

class EventSender {
    static let shared = EventSender()

    private let baseURL = Constants.API.baseURL
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func sendEvent(
        type: String,
        source: String = Constants.Sources.claudeDesktop,
        metadata: [String: String],
        sessionId: String? = nil
    ) async throws {
        guard let token = AuthManager.shared.authToken else {
            throw EventError.notAuthenticated
        }

        let event = Event(
            type: type,
            source: source,
            metadata: metadata,
            tabId: nil,
            sessionId: sessionId
        )

        guard let url = URL(string: "\(baseURL)/event") else {
            throw EventError.sendFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.App.version, forHTTPHeaderField: "X-App-Version")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(event)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            // Token expired, trigger re-auth
            await MainActor.run {
                AuthManager.shared.logout()
            }
            throw EventError.notAuthenticated
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EventError.sendFailed
        }

        print("[EventSender] Event sent: type=\(type), source=\(source)")
    }

    // Convenience methods for specific event types

    func sendPromptEvent(text: String, correlationId: String, sessionId: String?) async {
        do {
            try await sendEvent(
                type: Constants.EventTypes.aiPromptSubmitted,
                metadata: [
                    "text": text,
                    "correlationId": correlationId
                ],
                sessionId: sessionId
            )
        } catch {
            print("[EventSender] Failed to send prompt event: \(error)")
        }
    }

    func sendResponseEvent(text: String, correlationId: String, sessionId: String?) async {
        do {
            try await sendEvent(
                type: Constants.EventTypes.aiResponseReceived,
                metadata: [
                    "text": text,
                    "correlationId": correlationId
                ],
                sessionId: sessionId
            )
        } catch {
            print("[EventSender] Failed to send response event: \(error)")
        }
    }

    func sendSessionStartEvent(sessionId: String) async {
        do {
            try await sendEvent(
                type: Constants.EventTypes.sessionStarted,
                metadata: [
                    "startTime": ISO8601DateFormatter().string(from: Date())
                ],
                sessionId: sessionId
            )
        } catch {
            print("[EventSender] Failed to send session start event: \(error)")
        }
    }

    func sendSessionEndEvent(session: MonitoringSession) async {
        do {
            try await sendEvent(
                type: Constants.EventTypes.sessionEnded,
                metadata: session.toMetadata(),
                sessionId: session.id
            )
        } catch {
            print("[EventSender] Failed to send session end event: \(error)")
        }
    }

    func sendActivityEvent(sessionId: String?) async {
        do {
            try await sendEvent(
                type: Constants.EventTypes.userActivity,
                metadata: [
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ],
                sessionId: sessionId
            )
        } catch {
            print("[EventSender] Failed to send activity event: \(error)")
        }
    }
}
