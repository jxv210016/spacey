import ApplicationServices
import Combine
import Foundation

/// Live, observable Accessibility-permission status. Updates **instantly** when the
/// user toggles Spacey in System Settings — it listens for the system's
/// accessibility-changed distributed notification and re-checks `AXIsProcessTrusted()`,
/// with a short poll as a backstop in case the notification is missed.
@MainActor
final class AccessibilityMonitor: ObservableObject {
    @Published private(set) var isTrusted: Bool

    private var timer: Timer?
    private var observer: NSObjectProtocol?

    /// Posted by the system whenever Accessibility API authorization changes.
    private static let changedNotification = Notification.Name("com.apple.accessibility.api")

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    func start() {
        refresh()

        observer = DistributedNotificationCenter.default().addObserver(
            forName: Self.changedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // The flag can lag the notification by a hair; check now and again shortly.
            MainActor.assumeIsolated {
                self?.refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    MainActor.assumeIsolated { self?.refresh() }
                }
            }
        }

        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
            self.observer = nil
        }
    }

    /// Open Accessibility settings and prompt (also surfaces the system grant dialog).
    func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isTrusted { isTrusted = trusted }
    }

    deinit {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        timer?.invalidate()
    }
}
