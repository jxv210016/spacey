import XCTest
@testable import Spacey

/// The onboarding "instant jumps" button deep-links into System Settings. A typo in the
/// scheme string would silently no-op (the opener guards `URL(string:)`), so we assert
/// the link string parses into a URL and uses the expected scheme.
final class OnboardingLinksTests: XCTestCase {
    func testKeyboardSettingsLinkIsValid() {
        let url = URL(string: OnboardingLinks.keyboardSettings)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "x-apple.systempreferences")
    }
}
