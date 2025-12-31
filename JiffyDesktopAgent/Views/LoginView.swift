import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager = AuthManager.shared
    @State private var step: AuthStep = .initial

    enum AuthStep {
        case initial
        case waitingForLogin
        case readyToConnect
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Logo/Icon
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Sign In to Jiffy Labs")
                .font(.title2)
                .fontWeight(.semibold)

            switch step {
            case .initial:
                initialView
            case .waitingForLogin:
                waitingView
            case .readyToConnect:
                connectView
            }

            if let error = authManager.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(.secondary)
            .padding(.bottom)
        }
        .frame(width: 380, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()

                // Start monitoring if Claude is running
                if SessionManager.shared.isClaudeRunning {
                    SessionManager.shared.startSession()
                    AccessibilityMonitor.shared.startMonitoring()
                }
            }
        }
    }

    private var initialView: some View {
        VStack(spacing: 16) {
            Text("Click below to sign in with your browser.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                step = .waitingForLogin
                authManager.openLoginInBrowser()
            }) {
                Label("Sign In with Browser", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
        }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            Text("After signing in on the web, click the button below to connect this app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                step = .readyToConnect
                authManager.openDesktopAuthPage()
            }) {
                Label("I've Signed In - Connect App", systemImage: "link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
            .padding(.horizontal, 40)

            Button("Open Sign In Page Again") {
                authManager.openLoginInBrowser()
            }
            .foregroundStyle(.blue)
            .font(.caption)
        }
    }

    private var connectView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Waiting for authentication...")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("If nothing happens, click below to try again.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                authManager.openDesktopAuthPage()
            }
            .foregroundStyle(.blue)
        }
    }
}

#Preview {
    LoginView()
}
