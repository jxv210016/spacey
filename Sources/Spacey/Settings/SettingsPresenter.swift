import AppKit
import SwiftUI

/// Presents Settings in a managed `NSWindow`, the same reliable pattern as
/// `OnboardingPresenter`. The SwiftUI `Settings` scene's `showSettingsWindow:` action
/// silently no-ops for an `.accessory` menu-bar app, so we own the window instead.
@MainActor
final class SettingsPresenter: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show(model: AppModel) {
        AppActivation.becomeRegular()

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NSHostingController(rootView: SettingsView(model: model))
        let window = NSWindow(contentViewController: controller)
        window.title = "\(AppInfo.name) Settings"
        window.styleMask = [.titled, .closable]
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.window = window
    }

    func windowWillClose(_: Notification) {
        window = nil
    }
}
