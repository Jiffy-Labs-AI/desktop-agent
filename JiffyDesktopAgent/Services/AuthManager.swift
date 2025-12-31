import Foundation
import Combine
import AppKit

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Check for existing auth on init
        checkExistingAuth()
    }

    var authToken: String? {
        get { keychain.authToken }
        set { keychain.authToken = newValue }
    }

    private func checkExistingAuth() {
        guard let token = authToken else {
            isAuthenticated = false
            return
        }

        // Validate token by fetching current user
        Task {
            await validateToken(token)
        }
    }

    @MainActor
    private func validateToken(_ token: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await fetchCurrentUser(token: token)
            self.user = user
            self.isAuthenticated = true
            self.error = nil
        } catch {
            // Token is invalid, clear it
            self.authToken = nil
            self.isAuthenticated = false
            self.user = nil
            self.error = "Session expired. Please log in again."
        }
    }

    func handleAuthCallback(token: String) async {
        await MainActor.run {
            self.authToken = token
            self.isLoading = true
        }

        do {
            let user = try await fetchCurrentUser(token: token)
            await MainActor.run {
                self.user = user
                self.keychain.userId = user.id
                self.isAuthenticated = true
                self.isLoading = false
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.authToken = nil
                self.isAuthenticated = false
                self.isLoading = false
                self.error = "Failed to authenticate: \(error.localizedDescription)"
            }
        }
    }

    private func fetchCurrentUser(token: String) async throws -> User {
        guard let url = URL(string: "\(Constants.API.baseURL)/users/current") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.App.version, forHTTPHeaderField: "X-App-Version")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AuthError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            throw AuthError.serverError(httpResponse.statusCode)
        }

        let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        return userResponse.user
    }

    @MainActor
    func logout() {
        authToken = nil
        keychain.userId = nil
        user = nil
        isAuthenticated = false
        error = nil

        // Stop monitoring
        AccessibilityMonitor.shared.stopMonitoring()
        SessionManager.shared.endSession()
    }

    // Open the system browser for authentication
    func openLoginInBrowser() {
        // First open the auth page to log in, then redirect to desktop-auth
        guard let url = URL(string: Constants.API.authURL) else {
            error = "Invalid login URL"
            return
        }

        // Open in default browser
        NSWorkspace.shared.open(url)
    }

    // Open the desktop auth page (for users already logged in)
    func openDesktopAuthPage() {
        guard let url = URL(string: Constants.API.desktopAuthURL) else {
            error = "Invalid desktop auth URL"
            return
        }

        NSWorkspace.shared.open(url)
    }
}

enum AuthError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case noToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized - please log in again"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noToken:
            return "No authentication token"
        }
    }
}
