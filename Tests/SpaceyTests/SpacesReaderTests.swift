import XCTest
@testable import Spacey

final class SpacesReaderTests: XCTestCase {
    /// Mirrors the shape SkyLight returns from `SLSCopyManagedDisplaySpaces`.
    /// Note: the first space has an empty UUID — this is what the real API returns
    /// for the original login space (verified on-device). Only its ManagedSpaceID
    /// identifies it.
    private let fixture: [[String: Any]] = [
        [
            "Display Identifier": "Main",
            "Current Space": ["uuid": "", "ManagedSpaceID": 1, "id64": 1, "type": 0],
            "Spaces": [
                ["uuid": "", "ManagedSpaceID": 1, "id64": 1, "type": 0],
                ["uuid": "uuid-2", "ManagedSpaceID": 12, "type": 0]
            ]
        ],
        [
            "Display Identifier": "ABC-DEF",
            "Current Space": ["uuid": "uuid-3", "ManagedSpaceID": 99, "id64": 99, "type": 4],
            "Spaces": [
                ["uuid": "uuid-3", "id64": 99, "type": 4]
            ]
        ]
    ]

    func testParsesDisplaysAndSpaces() {
        let displays = SpacesReader.parse(fixture)
        XCTAssertEqual(displays.count, 2)
        XCTAssertEqual(displays[0].spaces.count, 2)
        XCTAssertEqual(displays[1].spaces.count, 1)
    }

    func testIndexingIsOneBasedPerDisplayAndGlobal() {
        let spaces = SpacesReader.parse(fixture).flatMap(\.spaces)
        XCTAssertEqual(spaces.map(\.indexOnDisplay), [1, 2, 1])
        XCTAssertEqual(spaces.map(\.globalIndex), [1, 2, 3])
    }

    /// Regression: the original login space has an empty UUID, so current-space
    /// detection must match on ManagedSpaceID, not UUID.
    func testMarksCurrentSpaceByManagedIDIncludingEmptyUUIDSpace() {
        let spaces = SpacesReader.parse(fixture).flatMap(\.spaces)
        let current = spaces.filter(\.isCurrent)
        XCTAssertEqual(current.map(\.managedID), [1, 99])
        XCTAssertTrue(
            current.contains { $0.uuid.isEmpty },
            "empty-UUID primary space must still be detectable as current"
        )
    }

    func testReadsManagedIDFromEitherKey() {
        let spaces = SpacesReader.parse(fixture).flatMap(\.spaces)
        XCTAssertEqual(spaces.map(\.managedID), [1, 12, 99])
    }

    func testDetectsNonUserSpaceType() {
        let spaces = SpacesReader.parse(fixture).flatMap(\.spaces)
        XCTAssertTrue(spaces[0].isUserSpace)
        XCTAssertFalse(spaces[2].isUserSpace)
    }

    /// The empty-UUID space must still get a stable, non-empty naming key.
    func testIdentityIsNonEmptyForPrimarySpace() {
        let spaces = SpacesReader.parse(fixture).flatMap(\.spaces)
        XCTAssertEqual(spaces[0].identity, "primary@Main")
        XCTAssertEqual(spaces[1].identity, "uuid-2")
        XCTAssertFalse(spaces[0].id.isEmpty)
    }
}
