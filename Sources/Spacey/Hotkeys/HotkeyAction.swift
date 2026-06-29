import Carbon.HIToolbox

/// The set of things a global hotkey can trigger. Each case is independently
/// assignable and clearable from the Shortcuts settings pane, persisted by
/// `HotkeyBindings`, and registered with the system by `HotkeyManager`.
///
/// Per-Space direct-jump hotkeys (jump straight to "Code", "Email", …) are
/// deliberately **deferred**: they need a dynamic, per-Space binding UI and storage
/// keyed by Space identity, which is a larger surface than this phase covers.
enum HotkeyAction: String, CaseIterable, Identifiable, Codable {
    /// Show/hide the Quick Switcher palette.
    case toggleQuickSwitcher
    /// Jump back to the previously active Space (toggle between two Spaces).
    case previousSpace
    /// Move one Space to the right on the active display.
    case cycleNext
    /// Move one Space to the left on the active display.
    case cyclePrevious

    var id: String { rawValue }

    /// Title shown in the Shortcuts settings pane.
    var title: String {
        switch self {
        case .toggleQuickSwitcher: return "Quick Switcher"
        case .previousSpace: return "Previous Space"
        case .cycleNext: return "Next Space"
        case .cyclePrevious: return "Previous (left) Space"
        }
    }

    /// One-line explanation shown under the title.
    var subtitle: String {
        switch self {
        case .toggleQuickSwitcher: return "Open the palette to search and jump to any Space."
        case .previousSpace: return "Toggle back to the Space you came from."
        case .cycleNext: return "Move one Space to the right."
        case .cyclePrevious: return "Move one Space to the left."
        }
    }

    /// The default chord, if any. Only the Quick Switcher ships with a default
    /// (⌥Space); the rest start unbound so the user opts in.
    var defaultCombo: KeyCombo? {
        switch self {
        case .toggleQuickSwitcher: return KeyCombo(keyCode: UInt16(kVK_Space), modifiers: .option)
        default: return nil
        }
    }

    /// The seed bindings used on first launch (before the user customizes anything).
    static var defaultBindings: [HotkeyAction: KeyCombo] {
        var result: [HotkeyAction: KeyCombo] = [:]
        for action in allCases {
            if let combo = action.defaultCombo { result[action] = combo }
        }
        return result
    }
}
