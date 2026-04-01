import SwiftUI
import ClaudeUsageCore

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct ClaudeUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var usageService = UsageService()

    private var isPeak: Bool {
        PeakTimeHelper.status().isPeak
    }

    private var menuBarText: String {
        if let data = usageService.usageData {
            return "⬡ \(Int(data.sessionUsage))%"
        }
        return "⬡ --"
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(usageService: usageService)
        } label: {
            Text(menuBarText)
                .foregroundStyle(isPeak
                    ? Color(red: 0.83, green: 0.65, blue: 0.46)
                    : .primary)
                .onAppear {
                    usageService.startPolling()
                }
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 320, height: 300)
    }
}
