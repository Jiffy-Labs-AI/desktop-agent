import Foundation
import AppKit
import ApplicationServices

class AccessibilityMonitor: ObservableObject {
    static let shared = AccessibilityMonitor()

    @Published var isMonitoring = false
    @Published var hasAccessibilityPermission = false
    @Published var lastPrompt: String = ""
    @Published var lastResponse: String = ""

    private var timer: Timer?
    private var lastPromptText: String = ""
    private var lastResponseText: String = ""
    private var lastPromptHash: Int = 0
    private var lastResponseHash: Int = 0

    private init() {
        checkAccessibilityPermission()
    }

    // MARK: - Permission Check

    func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = trusted
        }
        return trusted
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Check again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            _ = self.checkAccessibilityPermission()
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard !isMonitoring else { return }
        guard checkAccessibilityPermission() else {
            print("[AccessibilityMonitor] No accessibility permission")
            requestAccessibilityPermission()
            return
        }

        isMonitoring = true

        // Poll every 500ms for changes
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClaudeWindow()
        }

        print("[AccessibilityMonitor] Started monitoring")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("[AccessibilityMonitor] Stopped monitoring")
    }

    // MARK: - Window Inspection

    private func checkClaudeWindow() {
        guard let claudeApp = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == Constants.ClaudeApp.bundleIdentifier
        }) else {
            return
        }

        let appElement = AXUIElementCreateApplication(claudeApp.processIdentifier)

        // Get all windows
        var windowsValue: AnyObject?
        let windowsResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)

        guard windowsResult == .success,
              let windows = windowsValue as? [AXUIElement],
              let mainWindow = windows.first else {
            return
        }

        // Try to find text areas in the window
        inspectElement(mainWindow, depth: 0)
    }

    private func inspectElement(_ element: AXUIElement, depth: Int) {
        guard depth < 15 else { return } // Prevent infinite recursion

        // Get the role of this element
        var roleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        let role = roleValue as? String

        // Check for text content in text areas and text fields
        if role == kAXTextAreaRole as String || role == kAXTextFieldRole as String || role == kAXStaticTextRole as String {
            if let text = getTextValue(element), !text.isEmpty {
                processTextContent(text, role: role ?? "unknown")
            }
        }

        // Check for web areas (Claude might use a web view)
        if role == "AXWebArea" {
            inspectWebArea(element)
        }

        // Recursively check children
        var childrenValue: AnyObject?
        let childrenResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)

        if childrenResult == .success, let children = childrenValue as? [AXUIElement] {
            for child in children {
                inspectElement(child, depth: depth + 1)
            }
        }
    }

    private func inspectWebArea(_ element: AXUIElement) {
        // Web views might have different structure
        // Try to find text content within
        var childrenValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)

        if let children = childrenValue as? [AXUIElement] {
            for child in children {
                inspectElement(child, depth: 0)
            }
        }
    }

    private func getTextValue(_ element: AXUIElement) -> String? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)

        if result == .success, let text = value as? String {
            return text
        }

        // Try description as fallback
        var descValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descValue)
        return descValue as? String
    }

    private func processTextContent(_ text: String, role: String) {
        let textHash = text.hashValue
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        // Heuristic: Shorter texts are likely prompts, longer texts are likely responses
        // This is a simplified approach - in production you'd want more sophisticated detection
        let isLikelyPrompt = trimmedText.count < 500 && role == kAXTextAreaRole as String
        let isLikelyResponse = trimmedText.count > 100

        if isLikelyPrompt && textHash != lastPromptHash {
            // Detected new prompt
            lastPromptHash = textHash
            lastPromptText = trimmedText

            DispatchQueue.main.async {
                self.lastPrompt = trimmedText
            }

            let correlationId = generateCorrelationId()

            Task {
                await EventSender.shared.sendPromptEvent(
                    text: trimmedText,
                    correlationId: correlationId,
                    sessionId: SessionManager.shared.currentSessionId
                )
                SessionManager.shared.incrementPromptCount()
            }

            print("[AccessibilityMonitor] Prompt captured: \(trimmedText.prefix(50))...")
        }

        if isLikelyResponse && textHash != lastResponseHash && trimmedText != lastPromptText {
            // Detected new response
            lastResponseHash = textHash
            lastResponseText = trimmedText

            DispatchQueue.main.async {
                self.lastResponse = trimmedText
            }

            let correlationId = generateCorrelationId()

            Task {
                await EventSender.shared.sendResponseEvent(
                    text: trimmedText,
                    correlationId: correlationId,
                    sessionId: SessionManager.shared.currentSessionId
                )
                SessionManager.shared.incrementResponseCount()
            }

            print("[AccessibilityMonitor] Response captured: \(trimmedText.prefix(50))...")
        }
    }

    private func generateCorrelationId() -> String {
        let timestamp = Date().timeIntervalSince1970
        let random = Int.random(in: 1000...9999)
        return "\(Int(timestamp))-\(random)"
    }

    deinit {
        stopMonitoring()
    }
}
