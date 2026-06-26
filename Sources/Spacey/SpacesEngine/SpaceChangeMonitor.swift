import AppKit

/// Aggregates every signal that means "the Spaces layout may have changed" into a
/// single `onChange` callback:
///
///   1. `com.apple.spaces.plist` rewrites — structural changes (add/remove space,
///      some fullscreen transitions) via `SpacesPlistWatcher`.
///   2. `activeSpaceDidChangeNotification` — the user switched spaces.
///   3. `didChangeScreenParametersNotification` — a display was connected/removed
///      or rearranged.
///
/// All callbacks are delivered on the main queue.
@MainActor
final class SpaceChangeMonitor {
    private let onChange: () -> Void
    private let plistWatcher: SpacesPlistWatcher
    private var spaceObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        plistWatcher = SpacesPlistWatcher(onChange: onChange)
    }

    func start() {
        plistWatcher.start()

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        spaceObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [onChange] _ in onChange() }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [onChange] _ in onChange() }
    }

    func stop() {
        plistWatcher.stop()
        if let spaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver)
            self.spaceObserver = nil
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }

    deinit {
        if let spaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }
}
