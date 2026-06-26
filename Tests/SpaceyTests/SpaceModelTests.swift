import XCTest
@testable import Spacey

final class SpaceModelTests: XCTestCase {
    private func makeSpace(uuid: String, displayID: String = "Main", type: Int = 0) -> Space {
        Space(
            uuid: uuid,
            managedID: 1,
            displayID: displayID,
            indexOnDisplay: 1,
            globalIndex: 1,
            isCurrent: false,
            type: type
        )
    }

    func testIdentityPrefersUUIDWhenPresent() {
        XCTAssertEqual(makeSpace(uuid: "abc").identity, "abc")
    }

    func testIdentityFallsBackToPrimaryMarkerWhenUUIDEmpty() {
        XCTAssertEqual(makeSpace(uuid: "", displayID: "Main").identity, "primary@Main")
        XCTAssertEqual(makeSpace(uuid: "", displayID: "DISP-2").identity, "primary@DISP-2")
    }

    func testIdentityIsNeverEmpty() {
        XCTAssertFalse(makeSpace(uuid: "").identity.isEmpty)
        XCTAssertFalse(makeSpace(uuid: "x").identity.isEmpty)
    }

    func testIDEqualsIdentity() {
        let space = makeSpace(uuid: "")
        XCTAssertEqual(space.id, space.identity)
    }

    func testPrimarySpacesOnDifferentDisplaysHaveDistinctIdentity() {
        // Important for SwiftUI ForEach: two empty-UUID primary spaces (one per
        // display) must not collide on id.
        let first = makeSpace(uuid: "", displayID: "A")
        let second = makeSpace(uuid: "", displayID: "B")
        XCTAssertNotEqual(first.id, second.id)
    }

    func testIsUserSpaceOnlyForTypeZero() {
        XCTAssertTrue(makeSpace(uuid: "a", type: 0).isUserSpace)
        XCTAssertFalse(makeSpace(uuid: "a", type: 1).isUserSpace)
        XCTAssertFalse(makeSpace(uuid: "a", type: 4).isUserSpace)
        XCTAssertFalse(makeSpace(uuid: "a", type: -1).isUserSpace)
    }
}
