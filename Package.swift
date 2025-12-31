// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JiffyDesktopAgent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JiffyDesktopAgent", targets: ["JiffyDesktopAgent"])
    ],
    targets: [
        .executableTarget(
            name: "JiffyDesktopAgent",
            path: "JiffyDesktopAgent",
            exclude: ["Info.plist", "JiffyDesktopAgent.entitlements", "Resources/AppIcon.iconset"],
            sources: [
                "App",
                "Views",
                "Services",
                "Models",
                "Utils"
            ],
            resources: [
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/MenuBarIcon.png")
            ]
        )
    ]
)
