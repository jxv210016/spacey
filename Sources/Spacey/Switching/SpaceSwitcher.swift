import AppKit

/// Switches Spaces without SIP by driving the always-enabled "move one space left/right"
/// Mission Control shortcuts (⌃← / ⌃→, key codes 123/124) through System Events, stepping
/// ONE space at a time and CONFIRMING each step landed — via a live SkyLight read — before
/// sending the next.
///
/// This deliberately does NOT use the "Switch to Desktop N" symbolic hotkeys: macOS often
/// overwrites programmatic changes to those, so the plist can claim ⌃N is bound while the
/// keystroke no-ops. And firing all the relative arrows back-to-back lets the WindowServer
/// coalesce them during the switch animation, dropping presses. The closed loop here avoids
/// both: it never sends the next keystroke until it has observed the previous one take
/// effect, and it recomputes direction from the live current index each iteration so an
/// overshoot self-corrects.
///
/// Requires Accessibility + Automation permission. Raw synthetic key events get swallowed by
/// the WindowServer, but System Events is trusted.
enum SpaceSwitcher {
    /// Serial queue so overlapping requests can never interleave keystrokes, and the
    /// inter-step polling never blocks the UI.
    private static let queue = DispatchQueue(label: "com.getspacey.SpaceSwitcher")
    /// Guards `isSwitching` across the main thread (which sets up a request) and the
    /// background queue (which clears it).
    private static let lock = NSLock()
    /// True while a switch loop is in flight. Rapid repeats are ignored, never stacked.
    private static var isSwitching = false

    /// How often we re-read the live current index while waiting for a step to register.
    private static let pollInterval: TimeInterval = 0.05
    /// How long to wait for a single step to land before retrying / aborting.
    private static let stepTimeout: TimeInterval = 0.9

    /// Switch from the 1-based `current` index to `target` on the active display. The
    /// `displayCount` is retained for source compatibility with existing callers; the loop
    /// derives every bound it needs from live SkyLight reads.
    static func move(toIndex target: Int, fromIndex current: Int, displayCount: Int) {
        navigate(fromIndex: current, toIndex: target)
    }

    /// Step from the current 1-based Space index to the target on the same display using the
    /// confirmed, closed-loop relative stepper. Re-entrant calls while a loop is running are
    /// ignored.
    static func navigate(fromIndex current: Int, toIndex target: Int) {
        guard target != current else { return }

        lock.lock()
        if isSwitching {
            lock.unlock()
            return
        }
        isSwitching = true
        lock.unlock()

        queue.async {
            run(fromIndex: current, toIndex: target)
            lock.lock()
            isSwitching = false
            lock.unlock()
        }
    }

    /// The confirmed-step loop. Runs on the serial background queue.
    private static func run(fromIndex startIndex: Int, toIndex target: Int) {
        guard let displayID = activeDisplayID(expectedCurrentIndex: startIndex) else { return }

        // Bounded so a stuck switch can never spin forever. The distance plus the display's
        // Space count (with slack for an overshoot bounce) is always enough headroom.
        let spaceCount = max(spaceCount(onDisplay: displayID) ?? startIndex, target)
        let cap = 2 * max(abs(target - startIndex), spaceCount) + 4

        for _ in 0 ..< cap {
            guard let current = currentIndex(onDisplay: displayID) else { return }
            guard let keyCode = SpaceNavigation.stepKeyCode(from: current, to: target) else {
                return // current == target → done
            }
            // One retry if the first press doesn't land; then abort to avoid spinning.
            if !sendStepAndConfirm(keyCode: keyCode, displayID: displayID, before: current),
               !sendStepAndConfirm(keyCode: keyCode, displayID: displayID, before: current) {
                return
            }
        }
    }

    /// Send exactly one ⌃arrow, then poll the live current index until it changes from
    /// `before` or the timeout elapses. Returns `true` only if the index actually moved.
    private static func sendStepAndConfirm(keyCode: Int, displayID: String, before: Int) -> Bool {
        let source = "tell application \"System Events\" to key code \(keyCode) using control down"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if error != nil { return false }

        let deadline = Date().addingTimeInterval(stepTimeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: pollInterval)
            if let now = currentIndex(onDisplay: displayID), now != before {
                return true
            }
        }
        return false
    }

    // MARK: - Live snapshot helpers

    /// Identify the display the switch happens on. Prefer the one whose current Space sits at
    /// the expected starting index; otherwise any display that has a current Space (this
    /// covers the single-display case, where it's simply the only one).
    private static func activeDisplayID(expectedCurrentIndex: Int) -> String? {
        let snapshot = SpacesReader.snapshot()
        if let match = snapshot.first(where: {
            $0.spaces.first(where: \.isCurrent)?.indexOnDisplay == expectedCurrentIndex
        }) {
            return match.displayID
        }
        return snapshot.first(where: { $0.spaces.contains(where: \.isCurrent) })?.displayID
    }

    /// The live 1-based current index on `displayID`, or `nil` if it can't be read.
    private static func currentIndex(onDisplay displayID: String) -> Int? {
        SpacesReader.snapshot()
            .first(where: { $0.displayID == displayID })?
            .spaces.first(where: \.isCurrent)?
            .indexOnDisplay
    }

    /// The live number of Spaces on `displayID`.
    private static func spaceCount(onDisplay displayID: String) -> Int? {
        SpacesReader.snapshot().first(where: { $0.displayID == displayID })?.spaces.count
    }
}
