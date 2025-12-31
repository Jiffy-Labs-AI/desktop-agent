import Foundation
import AppKit
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var currentSession: MonitoringSession?
    @Published var isClaudeRunning = false
    @Published var isClaudeFocused = false

    private var focusTimer: Timer?
    private var appObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAppObservers()
    }

    var currentSessionId: String? {
        currentSession?.id
    }

    var totalFocusTime: TimeInterval {
        currentSession?.totalFocusTime ?? 0
    }

    // MARK: - Session Lifecycle

    func startSession() {
        guard currentSession == nil else { return }

        currentSession = MonitoringSession()
        startFocusTracking()

        // Send session start event
        if let sessionId = currentSessionId {
            Task {
                await EventSender.shared.sendSessionStartEvent(sessionId: sessionId)
            }
        }

        print("[SessionManager] Session started: \(currentSessionId ?? "unknown")")
    }

    func endSession() {
        guard var session = currentSession else { return }

        stopFocusTracking()
        session.end()

        // Send session end event
        Task {
            await EventSender.shared.sendSessionEndEvent(session: session)
        }

        print("[SessionManager] Session ended: \(session.id), duration: \(session.duration)s, focus: \(session.totalFocusTime)s")

        currentSession = nil
    }

    func incrementPromptCount() {
        currentSession?.incrementPromptCount()
    }

    func incrementResponseCount() {
        currentSession?.incrementResponseCount()
    }

    // MARK: - Focus Tracking

    private func startFocusTracking() {
        focusTimer?.invalidate()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFocusTime()
        }
    }

    private func stopFocusTracking() {
        focusTimer?.invalidate()
        focusTimer = nil
    }

    private func updateFocusTime() {
        if isClaudeFocused {
            currentSession?.addFocusTime(1.0)
        }
    }

    // MARK: - App Observers

    private func setupAppObservers() {
        // Check if Claude is running initially
        checkClaudeRunning()

        // Watch for app launches
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLaunch(notification)
        }

        // Watch for app terminations
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppTerminate(notification)
        }

        // Watch for app activation (focus)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivate(notification)
        }
    }

    private func checkClaudeRunning() {
        isClaudeRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Constants.ClaudeApp.bundleIdentifier
        }

        isClaudeFocused = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Constants.ClaudeApp.bundleIdentifier
    }

    private func handleAppLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == Constants.ClaudeApp.bundleIdentifier else {
            return
        }

        isClaudeRunning = true
        print("[SessionManager] Claude app launched")

        // Auto-start session when Claude launches
        if AuthManager.shared.isAuthenticated && currentSession == nil {
            startSession()
            AccessibilityMonitor.shared.startMonitoring()
        }
    }

    private func handleAppTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == Constants.ClaudeApp.bundleIdentifier else {
            return
        }

        isClaudeRunning = false
        isClaudeFocused = false
        print("[SessionManager] Claude app terminated")

        // End session when Claude closes
        endSession()
        AccessibilityMonitor.shared.stopMonitoring()
    }

    private func handleAppActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        isClaudeFocused = app.bundleIdentifier == Constants.ClaudeApp.bundleIdentifier
    }

    deinit {
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        focusTimer?.invalidate()
    }
}
