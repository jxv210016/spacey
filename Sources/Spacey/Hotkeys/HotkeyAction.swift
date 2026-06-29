import Carbon.HIToolbox

/// The set of things a global hotkey can trigger. Each case is independently
/// assignable and clearable from the Shortcuts settings pane, persisted by
/// `HotkeyBindings`, and registered with the system by `HotkeyManager`.
enum HotkeyAction: String, CaseIterable, Identifiable, Codable {
    /// Show/hide the Quick Switcher palette.
    case toggleQuickSwitcher
    /// Jump back to the previously active Space (toggle between two Spaces).
    case previousSpace
    /// Move one Space to the right on the active display.
    case cycleNext
    /// Move one Space to the left on the active display.
    case cyclePrevious
    /// Jump straight to the Nth Space on the active display (⌃1…⌃9 by default).
    case jumpToDesktop1, jumpToDesktop2, jumpToDesktop3, jumpToDesktop4, jumpToDesktop5
    case jumpToDesktop6, jumpToDesktop7, jumpToDesktop8, jumpToDesktop9

    var id: String {
        rawValue
    }

    /// For the positional jump actions, the 1-based desktop they target; `nil` otherwise.
    var targetDesktopNumber: Int? {
        switch self {
        case .jumpToDesktop1: return 1
        case .jumpToDesktop2: return 2
        case .jumpToDesktop3: return 3
        case .jumpToDesktop4: return 4
        case .jumpToDesktop5: return 5
        case .jumpToDesktop6: return 6
        case .jumpToDesktop7: return 7
        case .jumpToDesktop8: return 8
        case .jumpToDesktop9: return 9
        default: return nil
        }
    }

    /// Title shown in the Shortcuts settings pane.
    var title: String {
        if let number = targetDesktopNumber { return "Jump to Desktop \(number)" }
        switch self {
        case .toggleQuickSwitcher: return "Quick Switcher"
        case .previousSpace: return "Previous Space"
        case .cycleNext: return "Next Space"
        case .cyclePrevious: return "Previous (left) Space"
        default: return rawValue
        }
    }

    /// One-line explanation shown under the title.
    var subtitle: String {
        if let number = targetDesktopNumber { return "Switch straight to desktop \(number)." }
        switch self {
        case .toggleQuickSwitcher: return "Open the palette to search and jump to any Space."
        case .previousSpace: return "Toggle back to the Space you came from."
        case .cycleNext: return "Move one Space to the right."
        case .cyclePrevious: return "Move one Space to the left."
        default: return ""
        }
    }

    /// The default chord, if any. The Quick Switcher ships as ⌥Space and the nine
    /// positional jumps as ⌃1…⌃9; the relative-cycle actions start unbound so the
    /// user opts in. (⌃N mirrors macOS's own "Switch to Desktop N" chord, which is off by
    /// default — so Spacey owns it cleanly unless the user also turns the system one on.)
    var defaultCombo: KeyCombo? {
        if let number = targetDesktopNumber {
            return KeyCombo(keyCode: Self.digitKeyCode(number), modifiers: .control)
        }
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

    /// Virtual key code for number-row digit `number` (1…9).
    private static func digitKeyCode(_ number: Int) -> UInt16 {
        let codes = [
            kVK_ANSI_1,
            kVK_ANSI_2,
            kVK_ANSI_3,
            kVK_ANSI_4,
            kVK_ANSI_5,
            kVK_ANSI_6,
            kVK_ANSI_7,
            kVK_ANSI_8,
            kVK_ANSI_9
        ]
        let index = min(max(number, 1), codes.count) - 1
        return UInt16(codes[index])
    }
}
