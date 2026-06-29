import AppKit
import ApplicationServices

/// Create desktops without SIP by driving Mission Control's own "+" button via
/// Accessibility — the same action a user performs by hand. Briefly shows Mission
/// Control, since that's the UI being driven.
enum SpaceActions {
    /// Open Mission Control and press its "add desktop" button.
    static func addDesktop() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
        pressAddButton(attemptsRemaining: 10)
    }

    /// Mission Control's AX tree appears a beat after it opens, so retry a few times.
    private static func pressAddButton(attemptsRemaining: Int) {
        guard attemptsRemaining > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let button = addButton(), AXReader.press(button) { return }
            pressAddButton(attemptsRemaining: attemptsRemaining - 1)
        }
    }

    /// The add-desktop control is an `AXButton` whose label ("add desktop") may live in
    /// the title, description, or help depending on the macOS version, so match on all
    /// of them. As a fallback, accept any button whose label mentions "desktop".
    private static func addButton() -> AXUIElement? {
        guard let dock = AXReader.dock() else { return nil }
        return AXReader.firstDescendant(of: dock, maxDepth: 28) {
            guard AXReader.role($0) == "AXButton" else { return false }
            let label = AXReader.label($0)
            return label.contains("add desktop")
                || (label.contains("add") && label.contains("desktop"))
        }
    }
}
