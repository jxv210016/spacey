import SwiftUI
import XCTest
@testable import Spacey

final class ColorHexTests: XCTestCase {
    func testParsesSixDigitHexWithHash() throws {
        let rgb = try XCTUnwrap(ColorHex.rgb(from: "#FF8800"))
        XCTAssertEqual(rgb.red, 1.0, accuracy: 0.001)
        XCTAssertEqual(rgb.green, 0x88 / 255.0, accuracy: 0.001)
        XCTAssertEqual(rgb.blue, 0.0, accuracy: 0.001)
    }

    func testParsesWithoutHashAndIsCaseInsensitive() throws {
        let rgb = try XCTUnwrap(ColorHex.rgb(from: "00ff00"))
        XCTAssertEqual(rgb.green, 1.0, accuracy: 0.001)
        XCTAssertEqual(rgb.red, 0.0, accuracy: 0.001)
    }

    func testRejectsMalformed() {
        XCTAssertNil(ColorHex.rgb(from: ""))
        XCTAssertNil(ColorHex.rgb(from: "#FFF")) // 3-digit not supported
        XCTAssertNil(ColorHex.rgb(from: "#GGGGGG")) // non-hex
        XCTAssertNil(ColorHex.rgb(from: "#1234567")) // too long
        XCTAssertNil(ColorHex.rgb(from: "zzzzzz"))
    }

    func testNormalizeUppercasesAndAddsHash() {
        XCTAssertEqual(ColorHex.normalized("ff8800"), "#FF8800")
        XCTAssertEqual(ColorHex.normalized("#0a84ff"), "#0A84FF")
        XCTAssertNil(ColorHex.normalized("nope"))
    }

    func testColorInitFromHexSucceedsAndFailsAppropriately() {
        XCTAssertNotNil(Color(hex: "#0A84FF"))
        XCTAssertNil(Color(hex: "not-a-color"))
    }

    func testPaletteEntriesAreAllValidHex() {
        for swatch in SpacePalette.colors {
            XCTAssertNotNil(ColorHex.rgb(from: swatch.hex), "\(swatch.name) has invalid hex \(swatch.hex)")
        }
    }
}
