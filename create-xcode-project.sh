#!/bin/bash

# Script to set up Xcode project for Jiffy Desktop Agent
# Run this script to create a new Xcode project and copy all source files

echo "Creating Xcode project for Jiffy Desktop Agent..."

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE_PROJECT_DIR="$PROJECT_DIR/JiffyDesktopAgent.xcodeproj"

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode command line tools not found."
    echo "Please install Xcode from the App Store."
    exit 1
fi

echo ""
echo "=========================================="
echo "  Jiffy Desktop Agent - Xcode Setup"
echo "=========================================="
echo ""
echo "To set up the project in Xcode:"
echo ""
echo "1. Open Xcode"
echo ""
echo "2. Create New Project:"
echo "   - File → New → Project"
echo "   - Choose 'App' under macOS"
echo "   - Click Next"
echo ""
echo "3. Configure Project:"
echo "   - Product Name: JiffyDesktopAgent"
echo "   - Team: (Your development team)"
echo "   - Organization Identifier: com.jiffylabs"
echo "   - Bundle Identifier: com.jiffylabs.desktop-agent"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Storage: None"
echo "   - ✅ Include Tests: (optional)"
echo ""
echo "4. Save to: $PROJECT_DIR"
echo ""
echo "5. After project is created:"
echo "   - Delete the auto-generated ContentView.swift"
echo "   - Delete the auto-generated JiffyDesktopAgentApp.swift"
echo ""
echo "6. Add Source Files:"
echo "   - Right-click on JiffyDesktopAgent folder"
echo "   - 'Add Files to JiffyDesktopAgent...'"
echo "   - Navigate to $PROJECT_DIR/JiffyDesktopAgent"
echo "   - Select ALL folders (App, Views, Services, Models, Utils)"
echo "   - ✅ Copy items if needed: NO"
echo "   - ✅ Create groups"
echo "   - Add to target: JiffyDesktopAgent"
echo ""
echo "7. Add Info.plist:"
echo "   - Project → Target → Build Settings"
echo "   - Search for 'Info.plist'"
echo "   - Set path to: JiffyDesktopAgent/Info.plist"
echo ""
echo "8. Add Entitlements:"
echo "   - Project → Target → Signing & Capabilities"
echo "   - + Capability → Hardened Runtime (if needed)"
echo "   - Add entitlements file path in Build Settings"
echo ""
echo "9. Configure URL Scheme:"
echo "   - Project → Target → Info → URL Types"
echo "   - Add: jiffy-desktop"
echo ""
echo "10. Build and Run:"
echo "    - Press Cmd+R"
echo ""
echo "=========================================="
echo ""

# List all source files
echo "Source files to add:"
echo ""
find "$PROJECT_DIR/JiffyDesktopAgent" -name "*.swift" | while read file; do
    echo "  - ${file#$PROJECT_DIR/}"
done
echo ""

echo "Done! Follow the steps above to complete setup."
