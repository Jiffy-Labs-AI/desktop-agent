import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var accessibilityMonitor = AccessibilityMonitor.shared

    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("autoStartMonitoring") private var autoStartMonitoring = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            Form {
                // General Section
                Section("General") {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            setLaunchAtLogin(newValue)
                        }

                    Toggle("Auto-start Monitoring", isOn: $autoStartMonitoring)
                        .help("Automatically start monitoring when Claude is launched")

                    Toggle("Show Notifications", isOn: $showNotifications)
                }

                // Permissions Section
                Section("Permissions") {
                    HStack {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Accessibility")
                                Text(accessibilityMonitor.hasAccessibilityPermission ? "Granted" : "Required for monitoring")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: accessibilityMonitor.hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(accessibilityMonitor.hasAccessibilityPermission ? .green : .orange)
                        }

                        Spacer()

                        if !accessibilityMonitor.hasAccessibilityPermission {
                            Button("Grant Access") {
                                accessibilityMonitor.requestAccessibilityPermission()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    Button("Open System Preferences") {
                        openAccessibilityPreferences()
                    }
                    .buttonStyle(.borderless)
                }

                // Account Section
                Section("Account") {
                    if authManager.isAuthenticated {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(authManager.user?.displayName ?? "User")
                                    .font(.subheadline)
                                if let email = authManager.user?.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button("Sign Out") {
                                authManager.logout()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        Text("Not signed in")
                            .foregroundColor(.secondary)
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundColor(.secondary)
                    }

                    Link("Jiffy Labs Website", destination: URL(string: "https://jiffylabs.ai")!)

                    Link("Privacy Policy", destination: URL(string: "https://jiffylabs.ai/privacy")!)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 500)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[Settings] Failed to set launch at login: \(error)")
        }
    }

    private func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    SettingsView()
}
