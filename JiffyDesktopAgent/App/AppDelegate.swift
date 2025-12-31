import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching called")
        NSLog("[AppDelegate] Setting up menu bar...")
        setupMenuBar()
        setupURLScheme()

        // Check initial state
        if AuthManager.shared.isAuthenticated {
            // Check if Claude is running and auto-start if needed
            if SessionManager.shared.isClaudeRunning {
                if UserDefaults.standard.bool(forKey: "autoStartMonitoring") {
                    SessionManager.shared.startSession()
                    AccessibilityMonitor.shared.startMonitoring()
                }
            }
        }

        print("[AppDelegate] Jiffy Desktop Agent started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // End session gracefully
        SessionManager.shared.endSession()
        AccessibilityMonitor.shared.stopMonitoring()
        print("[AppDelegate] Jiffy Desktop Agent terminated")
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        NSLog("[AppDelegate] Creating status item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        NSLog("[AppDelegate] Status item created: \(statusItem != nil)")

        if let button = statusItem?.button {
            // Try to load the Jiffy logo from various locations
            var icon: NSImage?

            // Try Bundle.main first (for .app bundles)
            if let path = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png") {
                icon = NSImage(contentsOfFile: path)
            }

            // Try the module bundle (for Swift Package resources)
            if icon == nil, let path = Bundle.module.path(forResource: "MenuBarIcon", ofType: "png") {
                icon = NSImage(contentsOfFile: path)
            }

            // Try Resources folder in app bundle
            if icon == nil, let resourcePath = Bundle.main.resourcePath {
                let iconPath = (resourcePath as NSString).appendingPathComponent("MenuBarIcon.png")
                icon = NSImage(contentsOfFile: iconPath)
            }

            if let icon = icon {
                icon.isTemplate = true  // Makes it adapt to menu bar style (light/dark)
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                // Fall back to system icon
                button.image = NSImage(systemSymbolName: "eye.circle.fill", accessibilityDescription: "Jiffy")
            }

            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Ensure popover closes when clicking outside
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - URL Scheme Handling

    private func setupURLScheme() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        // Handle auth callback
        if url.scheme == Constants.API.callbackScheme {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                Task {
                    await AuthManager.shared.handleAuthCallback(token: token)

                    // Start monitoring if authenticated and Claude is running
                    await MainActor.run {
                        if AuthManager.shared.isAuthenticated && SessionManager.shared.isClaudeRunning {
                            SessionManager.shared.startSession()
                            AccessibilityMonitor.shared.startMonitoring()
                        }
                    }
                }
            }
        }
    }
}
