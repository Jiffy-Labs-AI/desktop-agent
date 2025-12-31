# Jiffy Desktop Agent

A macOS menu bar app that monitors your Claude desktop client interactions for productivity tracking.

## Features

- **Prompt Capture**: Automatically captures prompts sent to Claude desktop
- **Response Capture**: Captures Claude's responses
- **Usage Metrics**: Tracks session time and focus time
- **Jiffy Labs Integration**: Sends events to the Jiffy Labs platform

## Requirements

- macOS 13.0 or later
- Claude desktop app installed
- Jiffy Labs account

## Setup

### 1. Open in Xcode

```bash
cd JiffyDesktopAgent
open JiffyDesktopAgent.xcodeproj
```

Or create a new Xcode project:

1. Open Xcode
2. File → New → Project
3. Choose "App" under macOS
4. Set:
   - Product Name: JiffyDesktopAgent
   - Bundle Identifier: com.jiffylabs.desktop-agent
   - Interface: SwiftUI
   - Language: Swift
5. Replace the generated files with the files in `JiffyDesktopAgent/`

### 2. Configure Signing

1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Select your development team
4. Enable "Hardened Runtime" if code signing

### 3. Build and Run

Press `Cmd + R` to build and run the app.

## Usage

1. **Sign In**: Click the menu bar icon and sign in with your Jiffy Labs account
2. **Grant Permissions**: Allow accessibility access when prompted
3. **Monitor**: The app will automatically start monitoring when Claude is launched

## Permissions

The app requires:

- **Accessibility**: To read text from the Claude window
- **Network**: To send events to Jiffy Labs API

## Project Structure

```
JiffyDesktopAgent/
├── App/
│   ├── JiffyDesktopAgentApp.swift   # Main app entry
│   └── AppDelegate.swift             # Menu bar setup
├── Views/
│   ├── MenuBarView.swift             # Menu bar popover
│   ├── LoginView.swift               # Auth WebView
│   └── SettingsView.swift            # Settings panel
├── Services/
│   ├── AuthManager.swift             # Authentication
│   ├── AccessibilityMonitor.swift    # Claude monitoring
│   ├── EventSender.swift             # API client
│   └── SessionManager.swift          # Session tracking
├── Models/
│   ├── Event.swift                   # Event model
│   ├── User.swift                    # User model
│   └── Session.swift                 # Session model
└── Utils/
    ├── Constants.swift               # Configuration
    └── KeychainManager.swift         # Secure storage
```

## Development

### Debug Mode

In debug mode, the app connects to `localhost:3000` instead of production.

### Testing Accessibility

To test accessibility features:

1. Grant accessibility permission in System Preferences
2. Launch Claude desktop
3. Check console logs for captured events

## Troubleshooting

### App not detecting Claude

- Ensure Claude desktop is running
- Check that the bundle identifier matches: `com.anthropic.claudefordesktop`

### Accessibility not working

1. Open System Preferences → Privacy & Security → Accessibility
2. Remove and re-add Jiffy Desktop Agent
3. Restart the app

### Events not sending

- Check network connectivity
- Verify authentication status
- Check console for error messages

## License

Copyright © 2024 Jiffy Labs. All rights reserved.
