import XCTest
@testable import Spacey

@MainActor
final class OnboardingStateTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "spacey.test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testStartsIncompleteOnFreshSuite() {
        let state = OnboardingState(defaults: defaults)
        XCTAssertFalse(state.hasCompletedOnboarding)
        XCTAssertTrue(state.shouldShowOnboarding)
    }

    func testCompletePersistsAcrossInstances() {
        let first = OnboardingState(defaults: defaults)
        first.complete()
        XCTAssertTrue(first.hasCompletedOnboarding)
        XCTAssertFalse(first.shouldShowOnboarding)

        let second = OnboardingState(defaults: defaults)
        XCTAssertTrue(second.hasCompletedOnboarding)
        XCTAssertFalse(second.shouldShowOnboarding)
    }

    func testResetReopensOnboarding() {
        let state = OnboardingState(defaults: defaults)
        state.complete()
        state.reset()
        XCTAssertFalse(state.hasCompletedOnboarding)
        XCTAssertTrue(state.shouldShowOnboarding)

        let reloaded = OnboardingState(defaults: defaults)
        XCTAssertTrue(reloaded.shouldShowOnboarding)
    }
}
