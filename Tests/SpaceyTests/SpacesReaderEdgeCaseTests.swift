import XCTest
@testable import Spacey

/// Edge cases for `SpacesReader.parse` against malformed / partial / unusual data
/// shapes from the private SkyLight API. The API is undocumented and varies across
/// macOS builds, so the parser must never crash and must degrade gracefully.
final class SpacesReaderEdgeCaseTests: XCTestCase {
    // MARK: - Empty / missing structure

    func testEmptyInputReturnsEmpty() {
        XCTAssertTrue(SpacesReader.parse([]).isEmpty)
    }

    func testDisplayMissingIdentifierFallsBackToUnknown() {
        let result = SpacesReader.parse([["Spaces": [["uuid": "a", "ManagedSpaceID": 1]]]])
        XCTAssertEqual(result.first?.displayID, "Unknown")
    }

    func testDisplayMissingSpacesKeyYieldsNoSpacesButKeepsDisplay() {
        let result = SpacesReader.parse([["Display Identifier": "Main"]])
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result[0].spaces.isEmpty)
        XCTAssertNil(result[0].currentSpaceID)
    }

    func testEmptySpacesArrayWithCurrentSpacePresent() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Current Space": ["ManagedSpaceID": 5],
            "Spaces": [[String: Any]]()
        ]])
        XCTAssertTrue(result[0].spaces.isEmpty)
        XCTAssertEqual(result[0].currentSpaceID, 5)
    }

    func testDisplayMissingCurrentSpaceHasNoCurrent() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "a", "ManagedSpaceID": 1]]
        ]])
        XCTAssertNil(result[0].currentSpaceID)
        XCTAssertFalse(result[0].spaces.contains(where: \.isCurrent))
    }

    // MARK: - Malformed space dicts (must not crash)

    func testSpaceMissingTypeDoesNotCrashAndIsNotUserSpace() {
        // Regression: previously coerced a missing type through UInt64.max → Int trap.
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "a", "ManagedSpaceID": 1]] // no "type"
        ]])
        let space = result[0].spaces[0]
        XCTAssertEqual(space.type, -1)
        XCTAssertFalse(space.isUserSpace)
    }

    func testSpaceMissingBothIDsYieldsZero() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "a", "type": 0]]
        ]])
        XCTAssertEqual(result[0].spaces[0].managedID, 0)
    }

    func testUUIDWithWrongTypeFallsBackToEmpty() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": 12345, "ManagedSpaceID": 1, "type": 0]] // uuid is a number
        ]])
        XCTAssertEqual(result[0].spaces[0].uuid, "")
        XCTAssertEqual(result[0].spaces[0].identity, "primary@Main")
    }

    func testCompletelyEmptySpaceDictDoesNotCrash() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [[String: Any]()]
        ]])
        let space = result[0].spaces[0]
        XCTAssertEqual(space.uuid, "")
        XCTAssertEqual(space.managedID, 0)
        XCTAssertEqual(space.type, -1)
    }

    // MARK: - ID extraction precedence & coercion

    func testManagedSpaceIDTakesPrecedenceOverID64() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "a", "ManagedSpaceID": 7, "id64": 999, "type": 0]]
        ]])
        XCTAssertEqual(result[0].spaces[0].managedID, 7)
    }

    func testFallsBackToID64WhenManagedSpaceIDAbsent() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "a", "id64": 42, "type": 0]]
        ]])
        XCTAssertEqual(result[0].spaces[0].managedID, 42)
    }

    func testLargeManagedIDRoundTrips() {
        let big = UInt64.max - 3
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "a", "ManagedSpaceID": NSNumber(value: big), "type": 0]]
        ]])
        XCTAssertEqual(result[0].spaces[0].managedID, big)
    }

    func testCoercesIDFromNSNumberAndInt() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "a", "ManagedSpaceID": NSNumber(value: 3), "type": 0],
                ["uuid": "b", "ManagedSpaceID": 4, "type": 0]
            ]
        ]])
        XCTAssertEqual(result[0].spaces.map(\.managedID), [3, 4])
    }

    // MARK: - Space type classification

    func testFullscreenAndTiledTypesAreNotUserSpaces() {
        // Research shows fullscreen reports as 1 or 4 across builds — both are non-user.
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "a", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "b", "ManagedSpaceID": 2, "type": 1],
                ["uuid": "c", "ManagedSpaceID": 3, "type": 4]
            ]
        ]])
        XCTAssertEqual(result[0].spaces.map(\.isUserSpace), [true, false, false])
    }

    // MARK: - Current-space matching

    func testCurrentIDWithNoMatchingSpaceMarksNoneCurrent() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Current Space": ["ManagedSpaceID": 777],
            "Spaces": [["uuid": "a", "ManagedSpaceID": 1, "type": 0]]
        ]])
        XCTAssertFalse(result[0].spaces.contains(where: \.isCurrent))
    }

    func testCurrentMatchedViaID64Fallback() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Current Space": ["id64": 2], // only id64, no ManagedSpaceID
            "Spaces": [
                ["uuid": "a", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "b", "ManagedSpaceID": 2, "type": 0]
            ]
        ]])
        XCTAssertEqual(result[0].spaces.filter(\.isCurrent).map(\.managedID), [2])
    }

    func testOnlyOneSpacePerDisplayMarkedCurrent() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Current Space": ["ManagedSpaceID": 2],
            "Spaces": [
                ["uuid": "a", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "b", "ManagedSpaceID": 2, "type": 0],
                ["uuid": "c", "ManagedSpaceID": 3, "type": 0]
            ]
        ]])
        XCTAssertEqual(result[0].spaces.filter(\.isCurrent).count, 1)
    }

    // MARK: - Multi-display independence & indexing

    func testEachDisplayHasIndependentCurrent() {
        let result = SpacesReader.parse([
            [
                "Display Identifier": "A",
                "Current Space": ["ManagedSpaceID": 1],
                "Spaces": [["uuid": "a", "ManagedSpaceID": 1, "type": 0]]
            ],
            [
                "Display Identifier": "B",
                "Current Space": ["ManagedSpaceID": 9],
                "Spaces": [
                    ["uuid": "b", "ManagedSpaceID": 8, "type": 0],
                    ["uuid": "c", "ManagedSpaceID": 9, "type": 0]
                ]
            ]
        ])
        XCTAssertEqual(result[0].currentSpaceID, 1)
        XCTAssertEqual(result[1].currentSpaceID, 9)
        XCTAssertEqual(result.flatMap(\.spaces).filter(\.isCurrent).map(\.uuid), ["a", "c"])
    }

    func testIndexingResetsPerDisplayButGlobalIsContinuous() {
        let result = SpacesReader.parse([
            ["Display Identifier": "A", "Spaces": [
                ["uuid": "a", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "b", "ManagedSpaceID": 2, "type": 0]
            ]],
            ["Display Identifier": "B", "Spaces": [
                ["uuid": "c", "ManagedSpaceID": 3, "type": 0]
            ]]
        ])
        let spaces = result.flatMap(\.spaces)
        XCTAssertEqual(spaces.map(\.indexOnDisplay), [1, 2, 1])
        XCTAssertEqual(spaces.map(\.globalIndex), [1, 2, 3])
    }

    // MARK: - Live snapshot smoke (must not crash)

    func testSnapshotDoesNotCrash() {
        // On a headless CI runner this may return [] (no window-server connection);
        // the contract is simply that it never crashes and returns a valid array.
        let snapshot = SpacesReader.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.count, 0)
    }
}
