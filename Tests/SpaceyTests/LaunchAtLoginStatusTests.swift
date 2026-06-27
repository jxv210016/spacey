import ServiceManagement
import XCTest
@testable import Spacey

final class LaunchAtLoginStatusTests: XCTestCase {
    func testEnabledStatusMapsToTrue() {
        XCTAssertTrue(LaunchAtLoginStatus.isEnabled(for: .enabled))
    }

    func testNotRegisteredMapsToFalse() {
        XCTAssertFalse(LaunchAtLoginStatus.isEnabled(for: .notRegistered))
    }

    func testNotFoundMapsToFalse() {
        XCTAssertFalse(LaunchAtLoginStatus.isEnabled(for: .notFound))
    }

    func testRequiresApprovalMapsToFalse() {
        XCTAssertFalse(LaunchAtLoginStatus.isEnabled(for: .requiresApproval))
    }
}
