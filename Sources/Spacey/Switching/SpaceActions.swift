import AppKit
import ApplicationServices

/// Create desktops without SIP by driving Mission Control's own "+" button via
/// Accessibility — the same action a user performs by hand. Briefly shows Mission
/// Control, since that's the UI being driven.
enum SpaceActions {
    /// Open Mission Control and press its "add desktop" button.
    static func addDesktop() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
        pressAddButton(attemptsRemaining: 6)
    }

    /// Mission Control's AX tree appears a beat after it opens, so retry a few times.
    private static func pressAddButton(attemptsRemaining: Int) {
        guard attemptsRemaining > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let button = addButton(), AXReader.press(button) { return }
            pressAddButton(attemptsRemaining: attemptsRemaining - 1)
        }
    }

    private static func addButton() -> AXUIElement? {
        guard let dock = AXReader.dock() else { return nil }
        return AXReader.firstDescendant(of: dock, maxDepth: 24) {
            AXReader.role($0) == "AXButton" && AXReader.title($0).lowercased().contains("add desktop")
        }
    }
}
