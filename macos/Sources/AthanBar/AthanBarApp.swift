import AppKit
import SwiftUI

@main
struct AthanBarApp: App {
    @StateObject private var prayers = PrayerService()
    @StateObject private var audio = AdhanPlayer()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(prayers: prayers, audio: audio) {
                NSApp.terminate(nil)
            }
            .onAppear {
                audio.attach(prayerService: prayers)
                appDelegate.configureAsAgent()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                Text(prayers.menuBarText)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureAsAgent()
    }

    func configureAsAgent() {
        NSApp.setActivationPolicy(.accessory)
    }
}
