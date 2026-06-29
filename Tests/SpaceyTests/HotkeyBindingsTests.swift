import XCTest
@testable import Spacey

final class HotkeyBindingsTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "com.getspacey.tests.hotkeys.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @MainActor
    func testSeedsDefaultsOnFirstLaunch() throws {
        let bindings = HotkeyBindings(defaults: try makeDefaults())
        // The Quick Switcher ships with a default; the others start unbound.
        XCTAssertNotNil(bindings.combo(for: .toggleQuickSwitcher))
        XCTAssertNil(bindings.combo(for: .previousSpace))
    }

    @MainActor
    func testSetAndClearPersist() throws {
        let defaults = try makeDefaults()
        let bindings = HotkeyBindings(defaults: defaults)

        let combo = KeyCombo(keyCode: 12, modifiers: [.command, .shift])
        bindings.set(combo, for: .previousSpace)
        XCTAssertEqual(bindings.combo(for: .previousSpace), combo)

        // A fresh instance over the same suite should see the persisted value.
        let reloaded = HotkeyBindings(defaults: defaults)
        XCTAssertEqual(reloaded.combo(for: .previousSpace), combo)

        // Clearing persists too — and does not spring back to a default.
        reloaded.clear(.toggleQuickSwitcher)
        let reloadedAgain = HotkeyBindings(defaults: defaults)
        XCTAssertNil(reloadedAgain.combo(for: .toggleQuickSwitcher))
    }
}
