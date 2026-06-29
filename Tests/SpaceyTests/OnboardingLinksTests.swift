import XCTest
@testable import Spacey

/// The onboarding "Make it instant" buttons deep-link into System Settings. A typo in a
/// scheme string would silently no-op (the opener guards `URL(string:)`), so we assert
/// the link strings parse into URLs and use the expected scheme.
final class OnboardingLinksTests: XCTestCase {
    func testKeyboardSettingsLinkIsValid() {
        let url = URL(string: OnboardingLinks.keyboardSettings)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "x-apple.systempreferences")
    }

    func testAccessibilitySettingsLinkIsValid() {
        let url = URL(string: OnboardingLinks.accessibilitySettings)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "x-apple.systempreferences")
    }
}
