import AppKit
import Carbon.HIToolbox

/// Inspects macOS's built-in Mission Control keyboard shortcuts so switching can pick the
/// most robust mechanism available.
///
/// The "Switch to Desktop N" shortcuts (a single, direct jump) are far more reliable than
/// stepping Control-Arrow N times, but they're disabled by default. We only drive ⌃N when
/// we've confirmed it's actually bound to "Switch to Desktop N" — otherwise the keystroke
/// could trigger something unexpected in the frontmost app.
enum MissionControlShortcuts {
    /// macOS stores "Switch to Desktop 1" at symbolic-hotkey id 118, Desktop 2 at 119, …
    private static let switchToDesktopBaseID = 118
    /// `NSEvent.ModifierFlags.control` as stored in the symbolic-hotkeys plist.
    private static let controlModifierMask = 0x4_0000

    /// Number-row virtual key code for digit `number` (1…9).
    static func digitKeyCode(_ number: Int) -> UInt16 {
        let codes = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
                     kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
        let index = min(max(number, 1), codes.count) - 1
        return UInt16(codes[index])
    }

    /// Whether "Switch to Desktop `number`" is enabled and bound to plain ⌃`number`, so a
    /// synthetic ⌃`number` keystroke will jump straight there.
    static func canSwitchDirectly(toDesktop number: Int) -> Bool {
        guard (1 ... 9).contains(number),
              let prefs = UserDefaults(suiteName: "com.apple.symbolichotkeys"),
              let hotkeys = prefs.dictionary(forKey: "AppleSymbolicHotKeys"),
              let entry = hotkeys[String(switchToDesktopBaseID + number - 1)] as? [String: Any],
              isEnabled(entry),
              let value = entry["value"] as? [String: Any],
              let parameters = value["parameters"] as? [Any], parameters.count >= 3,
              let keyCode = (parameters[1] as? NSNumber)?.intValue,
              let modifiers = (parameters[2] as? NSNumber)?.intValue
        else { return false }
        return keyCode == Int(digitKeyCode(number)) && modifiers == controlModifierMask
    }

    private static func isEnabled(_ entry: [String: Any]) -> Bool {
        if let flag = entry["enabled"] as? Bool { return flag }
        if let number = entry["enabled"] as? NSNumber { return number.boolValue }
        return false
    }
}
