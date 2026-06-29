import XCTest
@testable import Spacey

final class IconSuggestionTests: XCTestCase {
    func testMatchesCommonNamesCaseInsensitively() {
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "Mail"), "envelope")
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "email"), "envelope")
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "Music"), "music.note")
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "GAMES"), "gamecontroller")
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "Work"), "hammer")
    }

    func testMatchesOnSubstringWithinAPhrase() {
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "Personal Email"), "envelope")
        XCTAssertEqual(IconSuggestion.symbol(forLabel: "Daily standup"), "video")
    }

    func testReturnsNilWhenNothingMatches() {
        XCTAssertNil(IconSuggestion.symbol(forLabel: "Zphqx"))
        XCTAssertNil(IconSuggestion.symbol(forLabel: ""))
        XCTAssertNil(IconSuggestion.colorHex(forLabel: "Zphqx"))
    }

    func testSuggestsAColorAlongsideTheSymbol() {
        XCTAssertEqual(IconSuggestion.colorHex(forLabel: "Mail"), "#0A84FF")
        XCTAssertNotNil(IconSuggestion.colorHex(forLabel: "Music"))
    }

    func testEverySuggestedColorIsValidHex() {
        for rule in IconSuggestion.rules {
            XCTAssertNotNil(ColorHex.normalized(rule.colorHex), "Invalid hex for \(rule.symbol): \(rule.colorHex)")
        }
    }
}
