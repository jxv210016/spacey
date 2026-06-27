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
