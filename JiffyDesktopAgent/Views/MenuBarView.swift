import SwiftUI

struct MenuBarView: View {
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var sessionManager = SessionManager.shared
    @ObservedObject var accessibilityMonitor = AccessibilityMonitor.shared

    @State private var showingLogin = false
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "eye.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Jiffy Desktop Agent")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            if authManager.isAuthenticated {
                authenticatedView
            } else {
                unauthenticatedView
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Settings") {
                    showingSettings = true
                }
                .foregroundStyle(.primary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .environment(\.colorScheme, .light)
        .sheet(isPresented: $showingLogin) {
            LoginView()
                .environment(\.colorScheme, .light)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(\.colorScheme, .light)
        }
    }

    private var authenticatedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                VStack(alignment: .leading) {
                    Text(authManager.user?.displayName ?? "User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let email = authManager.user?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Logout") {
                    authManager.logout()
                }
                .foregroundStyle(.blue)
                .font(.caption)
            }

            Divider()

            // Status
            VStack(alignment: .leading, spacing: 6) {
                statusRow(
                    icon: sessionManager.isClaudeRunning ? "checkmark.circle.fill" : "xmark.circle.fill",
                    color: sessionManager.isClaudeRunning ? .green : .gray,
                    label: "Claude Desktop",
                    value: sessionManager.isClaudeRunning ? "Running" : "Not Running"
                )

                statusRow(
                    icon: accessibilityMonitor.isMonitoring ? "eye.fill" : "eye.slash.fill",
                    color: accessibilityMonitor.isMonitoring ? .green : .orange,
                    label: "Monitoring",
                    value: accessibilityMonitor.isMonitoring ? "Active" : "Inactive"
                )

                if !accessibilityMonitor.hasAccessibilityPermission {
                    Button("Grant Accessibility Permission") {
                        accessibilityMonitor.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            // Session info
            if let session = sessionManager.currentSession {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Session")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Label("\(Int(session.totalFocusTime))s", systemImage: "clock")
                        Spacer()
                        Label("\(session.promptCount)", systemImage: "text.bubble")
                        Spacer()
                        Label("\(session.responseCount)", systemImage: "text.bubble.fill")
                    }
                    .font(.caption)
                }
            }

            // Manual controls
            HStack {
                if accessibilityMonitor.isMonitoring {
                    Button("Stop Monitoring") {
                        accessibilityMonitor.stopMonitoring()
                        sessionManager.endSession()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if sessionManager.isClaudeRunning {
                    Button("Start Monitoring") {
                        accessibilityMonitor.startMonitoring()
                        sessionManager.startSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }

    private var unauthenticatedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Sign in to start monitoring")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Sign In") {
                showingLogin = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func statusRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MenuBarView()
}
