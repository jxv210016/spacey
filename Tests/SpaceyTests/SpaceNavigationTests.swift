import XCTest
@testable import Spacey

final class SpaceNavigationTests: XCTestCase {
    func testCycleTargetForward() {
        XCTAssertEqual(SpaceNavigation.cycleTarget(currentIndex: 1, count: 3, delta: 1), 2)
    }

    func testCycleTargetBackward() {
        XCTAssertEqual(SpaceNavigation.cycleTarget(currentIndex: 2, count: 3, delta: -1), 1)
    }

    func testCycleTargetClampedAtEnds() {
        // No wrap: stepping off either end yields nil.
        XCTAssertNil(SpaceNavigation.cycleTarget(currentIndex: 3, count: 3, delta: 1))
        XCTAssertNil(SpaceNavigation.cycleTarget(currentIndex: 1, count: 3, delta: -1))
    }

    private func space(_ identity: String, current: Bool) -> Space {
        Space(
            uuid: identity,
            managedID: 1,
            displayID: "A",
            indexOnDisplay: 1,
            globalIndex: 1,
            isCurrent: current,
            type: 0
        )
    }

    @MainActor
    func testPreviousTrackerRecordsPriorSpace() {
        let tracker = PreviousSpaceTracker()
        tracker.record(current: space("a", current: true))
        XCTAssertNil(tracker.previousIdentity) // only one seen so far
        tracker.record(current: space("b", current: true))
        XCTAssertEqual(tracker.previousIdentity, "a")
        tracker.record(current: space("c", current: true))
        XCTAssertEqual(tracker.previousIdentity, "b")
    }

    @MainActor
    func testPreviousTrackerIgnoresRepeatsAndNils() {
        let tracker = PreviousSpaceTracker()
        tracker.record(current: space("a", current: true))
        tracker.record(current: space("a", current: true)) // same space, no change
        XCTAssertNil(tracker.previousIdentity)
        tracker.record(current: nil) // ignored
        tracker.record(current: space("b", current: true))
        XCTAssertEqual(tracker.previousIdentity, "a")
    }
}
