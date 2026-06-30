import XCTest
@testable import Spacey

/// Pins the naming-identity contract that custom Space names rely on, especially the
/// fragile empty-UUID "primary" login Space. `Space.identity` is the persistence key
/// for `SpaceNamesStore`, so any drift here silently orphans a user's saved names.
final class PrimarySpaceIdentityTests: XCTestCase {
    // MARK: - (a) Real-UUID Spaces keep their identity across reorders

    /// Reordering desktops changes `indexOnDisplay`/`globalIndex` but must NOT change
    /// a real-UUID Space's `identity`, so its custom name follows the move.
    func testRealUUIDIdentityIsStableAcrossReorder() {
        let before: [[String: Any]] = [[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "alpha", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "beta", "ManagedSpaceID": 2, "type": 0],
                ["uuid": "gamma", "ManagedSpaceID": 3, "type": 0]
            ]
        ]]
        // Same Spaces, reordered (gamma, alpha, beta) and with churned managedIDs
        // (managedID is not stable across sessions — identity must not depend on it).
        let after: [[String: Any]] = [[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "gamma", "ManagedSpaceID": 30, "type": 0],
                ["uuid": "alpha", "ManagedSpaceID": 10, "type": 0],
                ["uuid": "beta", "ManagedSpaceID": 20, "type": 0]
            ]
        ]]

        let identitiesBefore = SpacesReader.parse(before).flatMap(\.spaces)
            .reduce(into: [String: String]()) { $0[$1.uuid] = $1.identity }
        let identitiesAfter = SpacesReader.parse(after).flatMap(\.spaces)
            .reduce(into: [String: String]()) { $0[$1.uuid] = $1.identity }

        XCTAssertEqual(identitiesBefore, identitiesAfter)
        XCTAssertEqual(identitiesBefore["alpha"], "alpha")
        // Position changed for every Space, identity did not.
        let after0 = SpacesReader.parse(after).flatMap(\.spaces)
        XCTAssertEqual(after0.map(\.indexOnDisplay), [1, 2, 3])
        XCTAssertEqual(after0.map(\.uuid), ["gamma", "alpha", "beta"])
    }

    // MARK: - (b) Empty-UUID primary Space maps to primary@<displayID> and follows reorders

    func testEmptyUUIDSpaceMapsToPrimaryDisplayKey() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [["uuid": "", "ManagedSpaceID": 1, "type": 0]]
        ]])
        XCTAssertEqual(result[0].spaces[0].identity, "primary@Main")
    }

    /// The primary Space keeps reporting an empty UUID even when the user moves it to a
    /// different position; keying on `displayID` (not position) makes its name follow it.
    func testPrimaryIdentityFollowsReorderWithinDisplay() {
        // Primary login Space (empty UUID) sitting in the LAST slot after a reorder.
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "work", "ManagedSpaceID": 2, "type": 0],
                ["uuid": "play", "ManagedSpaceID": 3, "type": 0],
                ["uuid": "", "ManagedSpaceID": 1, "type": 0]
            ]
        ]])
        let primary = result[0].spaces.first { $0.uuid.isEmpty }
        XCTAssertEqual(primary?.indexOnDisplay, 3)
        XCTAssertEqual(primary?.identity, "primary@Main")
    }

    func testPrimaryIdentityIsPerDisplay() {
        let result = SpacesReader.parse([
            ["Display Identifier": "A", "Spaces": [["uuid": "", "ManagedSpaceID": 1, "type": 0]]],
            ["Display Identifier": "B", "Spaces": [["uuid": "", "ManagedSpaceID": 2, "type": 0]]]
        ])
        let identities = result.flatMap(\.spaces).map(\.identity)
        XCTAssertEqual(identities, ["primary@A", "primary@B"])
    }

    // MARK: - (c) Collision: two empty-UUID Spaces on one display resolve deterministically

    /// Defensive: if a display ever reports two empty-UUID Spaces, they must NOT share a
    /// single name record. The first keeps the canonical `primary@<displayID>` key so any
    /// already-saved name still loads; the second gets a distinct, deterministic key.
    func testTwoEmptyUUIDSpacesGetDistinctDeterministicKeys() {
        let display: [[String: Any]] = [[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "real", "ManagedSpaceID": 2, "type": 0],
                ["uuid": "", "ManagedSpaceID": 3, "type": 0]
            ]
        ]]
        let identities = SpacesReader.parse(display).flatMap(\.spaces).map(\.identity)

        // First empty-UUID Space keeps the backward-compatible canonical key.
        XCTAssertEqual(identities[0], "primary@Main")
        XCTAssertEqual(identities[1], "real")
        // Second empty-UUID Space is disambiguated, not collided onto the first.
        XCTAssertEqual(identities[2], "primary@Main#1")
        XCTAssertNotEqual(identities[0], identities[2])

        // Deterministic: parsing the same shape again yields the same keys.
        let identitiesAgain = SpacesReader.parse(display).flatMap(\.spaces).map(\.identity)
        XCTAssertEqual(identities, identitiesAgain)
    }

    /// The real-UUID Space sitting between two empty-UUID Spaces never participates in the
    /// empty-UUID ordinal scheme (its `primaryOrdinal` stays 0 / ignored).
    func testRealUUIDSpaceUnaffectedByEmptyUUIDOrdinalCounting() {
        let result = SpacesReader.parse([[
            "Display Identifier": "Main",
            "Spaces": [
                ["uuid": "", "ManagedSpaceID": 1, "type": 0],
                ["uuid": "keepme", "ManagedSpaceID": 2, "type": 0],
                ["uuid": "", "ManagedSpaceID": 3, "type": 0]
            ]
        ]])
        let real = result[0].spaces.first { $0.uuid == "keepme" }
        XCTAssertEqual(real?.identity, "keepme")
        XCTAssertEqual(real?.primaryOrdinal, 0)
    }
}
