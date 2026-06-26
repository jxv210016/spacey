import XCTest
@testable import Spacey

final class SpaceSelectionTests: XCTestCase {
    private func space(_ uuid: String, display: String, current: Bool) -> Space {
        Space(
            uuid: uuid,
            managedID: 1,
            displayID: display,
            indexOnDisplay: 1,
            globalIndex: 1,
            isCurrent: current,
            type: 0
        )
    }

    private func twoDisplays() -> [DisplaySpaces] {
        [
            DisplaySpaces(
                displayID: "A",
                spaces: [
                    space("a1", display: "A", current: false),
                    space("a2", display: "A", current: true)
                ],
                currentSpaceID: 1
            ),
            DisplaySpaces(
                displayID: "B",
                spaces: [space("b1", display: "B", current: true)],
                currentSpaceID: 1
            )
        ]
    }

    func testAllSpacesFlattensInOrder() {
        XCTAssertEqual(twoDisplays().allSpaces.map(\.uuid), ["a1", "a2", "b1"])
    }

    func testCurrentSpacePrefersActiveDisplay() {
        let current = twoDisplays().currentSpace(activeDisplayID: "B")
        XCTAssertEqual(current?.uuid, "b1")
    }

    func testCurrentSpaceUsesActiveDisplayEvenWhenAnotherIsAlsoCurrent() {
        let current = twoDisplays().currentSpace(activeDisplayID: "A")
        XCTAssertEqual(current?.uuid, "a2")
    }

    func testCurrentSpaceFallsBackWhenActiveDisplayUnknown() {
        // Unknown active display → first current across all displays.
        let current = twoDisplays().currentSpace(activeDisplayID: "does-not-exist")
        XCTAssertEqual(current?.uuid, "a2")
    }

    func testCurrentSpaceFallsBackWhenActiveDisplayIDNil() {
        let current = twoDisplays().currentSpace(activeDisplayID: nil)
        XCTAssertEqual(current?.uuid, "a2")
    }

    func testCurrentSpaceFallsBackWhenActiveDisplayHasNoCurrent() {
        let displays = [
            DisplaySpaces(
                displayID: "A",
                spaces: [space("a1", display: "A", current: false)],
                currentSpaceID: nil
            ),
            DisplaySpaces(
                displayID: "B",
                spaces: [space("b1", display: "B", current: true)],
                currentSpaceID: 1
            )
        ]
        // Active display A has no current space → fall back to B's current.
        XCTAssertEqual(displays.currentSpace(activeDisplayID: "A")?.uuid, "b1")
    }

    func testCurrentSpaceNilWhenNothingCurrent() {
        let displays = [
            DisplaySpaces(
                displayID: "A",
                spaces: [space("a1", display: "A", current: false)],
                currentSpaceID: nil
            )
        ]
        XCTAssertNil(displays.currentSpace(activeDisplayID: "A"))
    }

    func testDisplayLookup() {
        XCTAssertEqual(twoDisplays().display(withID: "B")?.displayID, "B")
        XCTAssertNil(twoDisplays().display(withID: "Z"))
        XCTAssertNil(twoDisplays().display(withID: nil))
    }
}
