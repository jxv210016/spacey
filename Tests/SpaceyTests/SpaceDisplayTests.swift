import XCTest
@testable import Spacey

final class SpaceDisplayTests: XCTestCase {
    private func space(index: Int = 2, global: Int = 5, type: Int = 0) -> Space {
        Space(
            uuid: "u",
            managedID: 1,
            displayID: "Main",
            indexOnDisplay: index,
            globalIndex: global,
            isCurrent: false,
            type: type
        )
    }

    func testTitleUsesCustomLabelWhenPresent() {
        XCTAssertEqual(SpaceDisplay.title(for: space(), name: SpaceName(label: "Work")), "Work")
    }

    func testTitleFallsBackToPositionalNumber() {
        XCTAssertEqual(SpaceDisplay.title(for: space(index: 2), name: nil), "Space 2")
        XCTAssertEqual(SpaceDisplay.title(for: space(index: 2), name: SpaceName(label: "  ")), "Space 2")
    }

    func testMenuBarTitleUsesNumberWhenUnnamed() {
        XCTAssertEqual(SpaceDisplay.menuBarTitle(for: space(global: 5), name: nil), "5")
    }

    func testMenuBarTitlePlaceholderWhenNoCurrentSpace() {
        XCTAssertEqual(SpaceDisplay.menuBarTitle(for: nil, name: nil), "–")
    }

    func testMenuBarTitleTruncatesLongLabels() {
        let long = SpaceName(label: "ReallyLongSpaceNameHere")
        let title = SpaceDisplay.menuBarTitle(for: space(), name: long, maxLength: 10)
        XCTAssertEqual(title.count, 10)
        XCTAssertTrue(title.hasSuffix("…"))
    }

    func testMenuBarTitleKeepsShortLabels() {
        XCTAssertEqual(SpaceDisplay.menuBarTitle(for: space(), name: SpaceName(label: "Work"), maxLength: 14), "Work")
    }

    func testSymbolUsesCustomWhenSet() {
        XCTAssertEqual(SpaceDisplay.symbol(for: space(), name: SpaceName(symbol: "hammer")), "hammer")
    }

    func testSymbolFallsBackByType() {
        XCTAssertEqual(SpaceDisplay.symbol(for: space(type: 0), name: nil), "square.dashed")
        XCTAssertEqual(SpaceDisplay.symbol(for: space(type: 4), name: nil), "rectangle.inset.filled")
    }

    func testSymbolUsesNameSuggestionWhenNoExplicitPick() {
        XCTAssertEqual(SpaceDisplay.symbol(for: space(), name: SpaceName(label: "Mail")), "envelope")
    }

    func testExplicitSymbolOverridesSuggestion() {
        let named = SpaceName(label: "Mail", symbol: "hammer")
        XCTAssertEqual(SpaceDisplay.symbol(for: space(), name: named), "hammer")
    }

    func testSymbolIgnoresSuggestionForUnnamedSpace() {
        XCTAssertEqual(SpaceDisplay.symbol(for: space(type: 0), name: SpaceName()), "square.dashed")
    }

    func testColorHexPrefersExplicitThenSuggestionThenNil() {
        XCTAssertEqual(
            SpaceDisplay.colorHex(for: space(), name: SpaceName(label: "Mail", colorHex: "#FFFFFF")),
            "#FFFFFF"
        )
        XCTAssertEqual(SpaceDisplay.colorHex(for: space(), name: SpaceName(label: "Mail")), "#0A84FF")
        XCTAssertNil(SpaceDisplay.colorHex(for: space(), name: SpaceName(label: "Zphqx")))
        XCTAssertNil(SpaceDisplay.colorHex(for: space(), name: nil))
    }

    func testIsNamed() {
        XCTAssertFalse(SpaceDisplay.isNamed(nil))
        XCTAssertFalse(SpaceDisplay.isNamed(SpaceName()))
        XCTAssertTrue(SpaceDisplay.isNamed(SpaceName(label: "Work")))
        XCTAssertTrue(SpaceDisplay.isNamed(SpaceName(symbol: "hammer")))
    }
}
