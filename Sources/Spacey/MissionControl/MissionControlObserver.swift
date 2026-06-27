import AppKit
import ApplicationServices

/// C-level AX observer callback. Captures nothing; routes to the instance via refcon.
private let missionControlAXCallback: AXObserverCallback = { _, _, notification, refcon in
    guard let refcon else { return }
    let observer = Unmanaged<MissionControlObserver>.fromOpaque(refcon).takeUnretainedValue()
    observer.handle(notification as String)
}

/// Observes `Dock.app` for Mission Control / Exposé activation via the (undocumented
/// but non-private) Accessibility notifications used by alt-tab-macos and
/// OpenMissionControl. Fires `onChange(true)` when the overview opens and
/// `onChange(false)` when it closes. Requires Accessibility permission.
///
/// Callbacks arrive on the main run loop.
final class MissionControlObserver {
    /// Opening notifications + the single exit notification.
    static let openNotifications = [
        "AXExposeShowAllWindows",
        "AXExposeShowFrontWindows",
        "AXExposeShowDesktop"
    ]
    static let exitNotification = "AXExposeExit"

    private let onChange: (Bool) -> Void
    private var observer: AXObserver?

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
    }

    func start() {
        guard observer == nil,
              let dockApp = NSWorkspace.shared.runningApplications
              .first(where: { $0.bundleIdentifier == "com.apple.dock" })
        else { return }

        let pid = dockApp.processIdentifier
        let dockElement = AXUIElementCreateApplication(pid)

        var created: AXObserver?
        guard AXObserverCreate(pid, missionControlAXCallback, &created) == .success, let created else { return }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        for name in Self.openNotifications + [Self.exitNotification] {
            AXObserverAddNotification(created, dockElement, name as CFString, refcon)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .defaultMode)
        observer = created
    }

    func stop() {
        guard let observer else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        self.observer = nil
    }

    deinit {
        stop()
    }

    fileprivate func handle(_ notification: String) {
        onChange(notification != Self.exitNotification)
    }
}
