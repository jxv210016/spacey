import AppKit
import Carbon.HIToolbox

/// A single global-hotkey chord: a virtual key code plus its modifier mask.
///
/// Stored modifiers are the `NSEvent.ModifierFlags` raw value masked to the four
/// chord modifiers (⌃⌥⇧⌘), so the type round-trips cleanly through `Codable` for
/// persistence and renders a human-readable string like `⌥Space`. The Carbon
/// registration API wants its own modifier constants, exposed via `carbonModifiers`.
struct KeyCombo: Codable, Hashable {
    /// Hardware-independent virtual key code (matches `NSEvent.keyCode` / `kVK_*`).
    let keyCode: UInt16
    /// `NSEvent.ModifierFlags` raw value, masked to ⌃⌥⇧⌘.
    let modifiers: UInt

    /// The modifiers we let participate in a chord. (Caps Lock, Fn, etc. are ignored.)
    static let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers.intersection(Self.relevantModifiers).rawValue
    }

    /// The modifier mask as `NSEvent.ModifierFlags`.
    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    /// Whether the chord carries at least one "real" modifier (⌃⌥⌘). A bare key or a
    /// Shift-only chord makes a poor global hotkey (it collides with normal typing), so
    /// the recorder rejects those.
    var hasCommandModifier: Bool {
        !modifierFlags.isDisjoint(with: [.command, .option, .control])
    }

    /// The modifier mask translated to the Carbon constants `RegisterEventHotKey` wants.
    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifierFlags.contains(.command) { result |= UInt32(cmdKey) }
        if modifierFlags.contains(.option) { result |= UInt32(optionKey) }
        if modifierFlags.contains(.control) { result |= UInt32(controlKey) }
        if modifierFlags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    /// A human-readable chord, e.g. `⌥⌘Space`, in Apple's canonical modifier order.
    var displayString: String {
        modifierSymbols + KeyCodeNames.symbol(for: keyCode)
    }

    private var modifierSymbols: String {
        var symbols = ""
        if modifierFlags.contains(.control) { symbols += "⌃" }
        if modifierFlags.contains(.option) { symbols += "⌥" }
        if modifierFlags.contains(.shift) { symbols += "⇧" }
        if modifierFlags.contains(.command) { symbols += "⌘" }
        return symbols
    }
}
