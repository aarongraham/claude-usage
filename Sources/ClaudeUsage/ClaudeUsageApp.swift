import SwiftUI

@main
struct ClaudeUsageApp: App {
    var body: some Scene {
        MenuBarExtra("⬡ --", systemImage: "hexagon") {
            Text("Claude Usage")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
