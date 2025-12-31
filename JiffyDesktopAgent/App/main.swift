import AppKit

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// For menu bar apps, we don't want activation policy to be regular
app.setActivationPolicy(.accessory)

NSLog("[main] Starting Jiffy Desktop Agent...")
app.run()
