import AppKit

/// Switches Spaces without SIP by driving the built-in "move one space left/right"
/// Mission Control shortcuts (Control+Arrow) through System Events, stepping
/// relatively from the current Space to the target.
///
/// Requires Accessibility + Automation permission and relies on the default
/// Control+Left/Right shortcuts being enabled (they are, out of the box). This is
/// the reliable no-SIP path — raw synthetic key events get swallowed by the
/// WindowServer, but System Events is trusted.
enum SpaceSwitcher {
    /// Switch from `current` to `target` (1-based indices on the same display), choosing
    /// the most robust mechanism: a single direct "Switch to Desktop N" jump when that
    /// shortcut is enabled and there's just one display (it's positional on the primary
    /// display), otherwise relative Control-Arrow stepping.
    static func move(toIndex target: Int, fromIndex current: Int, displayCount: Int) {
        guard target != current else { return }
        if displayCount == 1, MissionControlShortcuts.canSwitchDirectly(toDesktop: target) {
            jumpDirect(toDesktop: target)
        } else {
            navigate(fromIndex: current, toIndex: target)
        }
    }

    /// Directly jump to desktop `number` via the built-in ⌃N "Switch to Desktop" shortcut
    /// (one keystroke, no stepping). The caller must confirm the shortcut is enabled.
    static func jumpDirect(toDesktop number: Int) {
        let keyCode = MissionControlShortcuts.digitKeyCode(number)
        let source = "tell application \"System Events\" to key code \(keyCode) using control down"
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
        }
    }

    /// Step from the current 1-based Space index to the target on the same display.
    static func navigate(fromIndex current: Int, toIndex target: Int) {
        let delta = target - current
        guard delta != 0 else { return }

        let keyCode = delta > 0 ? 124 : 123 // right : left arrow
        let steps = abs(delta)

        var lines = ["tell application \"System Events\""]
        for step in 0 ..< steps {
            lines.append("key code \(keyCode) using control down")
            if step < steps - 1 { lines.append("delay 0.22") }
        }
        lines.append("end tell")
        let source = lines.joined(separator: "\n")

        // Off the main thread: the inter-step delays would otherwise block the UI.
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
        }
    }
}
