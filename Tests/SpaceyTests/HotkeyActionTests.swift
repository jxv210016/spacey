import Carbon.HIToolbox
import XCTest
@testable import Spacey

final class HotkeyActionTests: XCTestCase {
    func testJumpActionsMapToDesktopNumbers() {
        XCTAssertEqual(HotkeyAction.jumpToDesktop1.targetDesktopNumber, 1)
        XCTAssertEqual(HotkeyAction.jumpToDesktop9.targetDesktopNumber, 9)
        XCTAssertNil(HotkeyAction.toggleQuickSwitcher.targetDesktopNumber)
        XCTAssertNil(HotkeyAction.previousSpace.targetDesktopNumber)
    }

    func testThereAreNineJumpActions() {
        let jumps = HotkeyAction.allCases.filter { $0.targetDesktopNumber != nil }
        XCTAssertEqual(jumps.count, 9)
        XCTAssertEqual(Set(jumps.compactMap { $0.targetDesktopNumber }), Set(1 ... 9))
    }

    func testJumpDefaultsAreControlOptionDigit() throws {
        let combo = try XCTUnwrap(HotkeyAction.jumpToDesktop1.defaultCombo)
        XCTAssertEqual(combo.keyCode, UInt16(kVK_ANSI_1))
        XCTAssertTrue(combo.modifierFlags.contains(.control))
        XCTAssertTrue(combo.modifierFlags.contains(.option))
        XCTAssertFalse(combo.modifierFlags.contains(.command))

        let combo3 = try XCTUnwrap(HotkeyAction.jumpToDesktop3.defaultCombo)
        XCTAssertEqual(combo3.keyCode, UInt16(kVK_ANSI_3))
        XCTAssertEqual(combo3.displayString, "⌃⌥3")
    }

    func testDefaultBindingsSeedAllNineJumpsPlusQuickSwitcher() {
        let defaults = HotkeyAction.defaultBindings
        XCTAssertNotNil(defaults[.toggleQuickSwitcher])
        for number in 1 ... 9 {
            let action = try? XCTUnwrap(HotkeyAction.allCases.first { $0.targetDesktopNumber == number })
            XCTAssertNotNil(action.flatMap { defaults[$0] }, "expected a default for desktop \(number)")
        }
        // Relative-cycle actions stay unbound by default.
        XCTAssertNil(defaults[.cycleNext])
        XCTAssertNil(defaults[.cyclePrevious])
    }

    func testJumpTitlesAreHumanReadable() {
        XCTAssertEqual(HotkeyAction.jumpToDesktop5.title, "Jump to Desktop 5")
    }
}
