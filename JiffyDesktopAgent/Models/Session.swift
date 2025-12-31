import Foundation

struct MonitoringSession {
    let id: String
    let startTime: Date
    var endTime: Date?
    var totalFocusTime: TimeInterval
    var promptCount: Int
    var responseCount: Int

    init() {
        self.id = UUID().uuidString
        self.startTime = Date()
        self.endTime = nil
        self.totalFocusTime = 0
        self.promptCount = 0
        self.responseCount = 0
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isActive: Bool {
        return endTime == nil
    }

    mutating func end() {
        self.endTime = Date()
    }

    mutating func incrementPromptCount() {
        self.promptCount += 1
    }

    mutating func incrementResponseCount() {
        self.responseCount += 1
    }

    mutating func addFocusTime(_ seconds: TimeInterval) {
        self.totalFocusTime += seconds
    }

    func toMetadata() -> [String: String] {
        return [
            "sessionId": id,
            "duration": String(format: "%.0f", duration),
            "focusTime": String(format: "%.0f", totalFocusTime),
            "promptCount": String(promptCount),
            "responseCount": String(responseCount),
            "startTime": ISO8601DateFormatter().string(from: startTime),
            "endTime": endTime.map { ISO8601DateFormatter().string(from: $0) } ?? ""
        ]
    }
}
