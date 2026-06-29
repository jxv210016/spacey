import XCTest
@testable import Spacey

final class QuickSwitcherTests: XCTestCase {
    private func entry(_ id: String, title: String, current: Bool = false) -> QuickSwitcherEntry {
        QuickSwitcherEntry(
            id: id,
            title: title,
            symbol: "square",
            colorHex: nil,
            number: 1,
            isCurrent: current,
            displayID: "A",
            indexOnDisplay: 1
        )
    }

    private func sample() -> [QuickSwitcherEntry] {
        [
            entry("1", title: "Code"),
            entry("2", title: "Email"),
            entry("3", title: "Code Review")
        ]
    }

    // MARK: Filter

    func testEmptyQueryReturnsAll() {
        XCTAssertEqual(QuickSwitcherFilter.filter(sample(), query: "").count, 3)
        XCTAssertEqual(QuickSwitcherFilter.filter(sample(), query: "   ").count, 3)
    }

    func testFilterIsCaseInsensitiveSubstring() {
        let results = QuickSwitcherFilter.filter(sample(), query: "code")
        XCTAssertEqual(results.map(\.title), ["Code", "Code Review"])
    }

    func testFilterNoMatch() {
        XCTAssertTrue(QuickSwitcherFilter.filter(sample(), query: "zzz").isEmpty)
    }

    // MARK: Model selection

    @MainActor
    func testResetHighlightsCurrentSpace() {
        let model = QuickSwitcherModel()
        model.reset(entries: [entry("1", title: "A"), entry("2", title: "B", current: true)])
        XCTAssertEqual(model.selection, 1)
        XCTAssertEqual(model.selectedEntry?.id, "2")
    }

    @MainActor
    func testMoveSelectionWraps() {
        let model = QuickSwitcherModel()
        model.reset(entries: sample())
        model.moveSelection(by: -1) // from 0 wraps to last
        XCTAssertEqual(model.selection, 2)
        model.moveSelection(by: 1) // back to 0
        XCTAssertEqual(model.selection, 0)
    }

    @MainActor
    func testQueryNarrowsResultsAndClampsSelection() {
        let model = QuickSwitcherModel()
        model.reset(entries: sample())
        model.moveSelection(by: 1) // select index 2 (Code Review)... actually index 1
        model.query = "code"
        // Two results remain; selection must stay in range.
        XCTAssertEqual(model.results.map(\.title), ["Code", "Code Review"])
        XCTAssertLessThan(model.selection, model.results.count)
    }

    @MainActor
    func testEntryForNumber() {
        let model = QuickSwitcherModel()
        model.reset(entries: sample())
        XCTAssertEqual(model.entry(forNumber: 2)?.title, "Email")
        XCTAssertNil(model.entry(forNumber: 9))
        XCTAssertNil(model.entry(forNumber: 0))
    }

    @MainActor
    func testDeleteBackward() {
        let model = QuickSwitcherModel()
        model.reset(entries: sample())
        model.appendToQuery("co")
        model.deleteBackward()
        XCTAssertEqual(model.query, "c")
        model.deleteBackward()
        model.deleteBackward() // no-op on empty
        XCTAssertEqual(model.query, "")
    }
}
