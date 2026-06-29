import AppKit
import Carbon.HIToolbox
import XCTest
@testable import Spacey

final class KeyComboTests: XCTestCase {
    func testDisplayStringForOptionSpace() {
        let combo = KeyCombo(keyCode: UInt16(kVK_Space), modifiers: .option)
        XCTAssertEqual(combo.displayString, "⌥Space")
    }

    func testDisplayStringUsesCanonicalModifierOrder() {
        // Provide modifiers out of order; output must be ⌃⌥⇧⌘ then key.
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_A), modifiers: [.command, .shift, .control, .option])
        XCTAssertEqual(combo.displayString, "⌃⌥⇧⌘A")
    }

    func testModifiersMaskedToRelevantOnly() {
        // Caps Lock should be dropped from the stored mask.
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_B), modifiers: [.command, .capsLock])
        XCTAssertEqual(combo.modifierFlags, .command)
        XCTAssertEqual(combo.displayString, "⌘B")
    }

    func testHasCommandModifier() {
        XCTAssertTrue(KeyCombo(keyCode: 0, modifiers: .command).hasCommandModifier)
        XCTAssertTrue(KeyCombo(keyCode: 0, modifiers: .option).hasCommandModifier)
        XCTAssertTrue(KeyCombo(keyCode: 0, modifiers: .control).hasCommandModifier)
        // Shift alone is not a "real" modifier for a global hotkey.
        XCTAssertFalse(KeyCombo(keyCode: 0, modifiers: .shift).hasCommandModifier)
        XCTAssertFalse(KeyCombo(keyCode: 0, modifiers: []).hasCommandModifier)
    }

    func testCarbonModifiersMapping() {
        let combo = KeyCombo(keyCode: 0, modifiers: [.command, .option, .control, .shift])
        let expected = UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey) | UInt32(shiftKey)
        XCTAssertEqual(combo.carbonModifiers, expected)
    }

    func testCodableRoundTrip() throws {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_K), modifiers: [.command, .shift])
        let data = try JSONEncoder().encode(combo)
        let decoded = try JSONDecoder().decode(KeyCombo.self, from: data)
        XCTAssertEqual(decoded, combo)
        XCTAssertEqual(decoded.displayString, "⇧⌘K")
    }

    func testUnmappedKeyCodeFallback() {
        XCTAssertEqual(KeyCodeNames.symbol(for: 9999), "Key 9999")
    }
}
