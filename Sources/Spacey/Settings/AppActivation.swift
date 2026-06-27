import AppKit

/// Activation-policy helpers for a menu-bar-only (`.accessory`) app.
///
/// Opening a real window (Settings, Onboarding) from an `.accessory` app is unreliable:
/// the window can open behind other apps and never take focus. We briefly switch to
/// `.regular`, activate, then drive the standard Settings action. When the last titled
/// window closes we drop back to `.accessory` so the Dock icon and app menu disappear.
@MainActor
enum AppActivation {
    /// Bring the app forward as a regular app so a window can become key.
    static func becomeRegular() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Open the SwiftUI `Settings` scene, made reliable for an accessory app.
    static func openSettings() {
        becomeRegular()
        // macOS 13+ renamed the selector from `showPreferencesWindow:`.
        if NSApp.responds(to: Selector(("showSettingsWindow:"))) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    /// Start watching window closes; when no titled window remains visible, revert to
    /// `.accessory`. Safe to call once at startup.
    static func observeWindowClosures() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Defer until after the window has finished closing so it no longer counts.
            DispatchQueue.main.async {
                MainActor.assumeIsolated { revertToAccessoryIfNoWindows() }
            }
        }
    }

    private static func revertToAccessoryIfNoWindows() {
        let hasTitledWindow = NSApp.windows.contains { window in
            window.isVisible && window.styleMask.contains(.titled)
        }
        if !hasTitledWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
