import AppKit
import SwiftUI

/// Presents the onboarding flow in its own centered, Apple-style window (rather than a
/// Settings tab). Owns the `NSWindow` so it can be shown on first launch and re-opened
/// later ("Replay setup…"). Reuses one window if asked to show again.
@MainActor
final class OnboardingPresenter: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show(state: OnboardingState, accessibility: AccessibilityMonitor) {
        AppActivation.becomeRegular()

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let root = OnboardingView(
            state: state,
            accessibility: accessibility,
            onFinish: { [weak self] in self?.close() }
        )
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: controller)
        window.title = "Welcome to \(AppInfo.name)"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.delegate = self
        window.setContentSize(NSSize(width: 460, height: 560))
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.window = window
    }

    func close() {
        window?.close()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_: Notification) {
        window = nil
    }
}
