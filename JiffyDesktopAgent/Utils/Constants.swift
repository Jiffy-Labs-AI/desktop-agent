import Foundation

struct Constants {
    struct API {
        #if DEBUG
        static let baseURL = "http://localhost:3000/api"
        static let webURL = "http://localhost:3000"
        static let authURL = "http://localhost:3000/login"
        #else
        static let baseURL = "https://platform-jiffylabs.vercel.app/api"
        static let webURL = "https://platform-jiffylabs.vercel.app"
        static let authURL = "https://auth.jiffylabs.ai"
        #endif

        static let desktopAuthURL = "\(webURL)/desktop-auth"
        static let callbackScheme = "jiffy-desktop"
    }

    struct EventTypes {
        static let aiPromptSubmitted = "ai_prompt_submitted"
        static let aiResponseReceived = "ai_response_received"
        static let aiVisit = "ai_visit"
        static let userActivity = "user_activity"
        static let sessionStarted = "session_started"
        static let sessionEnded = "session_ended"
    }

    struct Sources {
        static let claudeDesktop = "claude_desktop"
    }

    struct ClaudeApp {
        static let bundleIdentifier = "com.anthropic.claudefordesktop"
        static let appName = "Claude"
    }

    struct Keychain {
        static let serviceName = "com.jiffylabs.desktop-agent"
        static let authTokenKey = "jiffy_auth_token"
        static let userIdKey = "jiffy_user_id"
    }

    struct App {
        static let version = "1.0.0"
        static let name = "Jiffy Desktop Agent"
    }
}
