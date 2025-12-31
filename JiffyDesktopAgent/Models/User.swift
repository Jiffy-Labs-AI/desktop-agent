import Foundation

struct User: Codable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let organizationId: String?
    let createdAt: String?
    let updatedAt: String?

    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else if let email = email {
            return email
        }
        return "User"
    }
}

struct UserResponse: Codable {
    let user: User
}

struct AuthState: Codable {
    var isAuthenticated: Bool
    var user: User?
    var token: String?
    var expiresAt: Date?

    static var empty: AuthState {
        AuthState(isAuthenticated: false, user: nil, token: nil, expiresAt: nil)
    }
}
