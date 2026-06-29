import XCTest
@testable import Spacey

final class SemanticVersionTests: XCTestCase {
    /// Parse a version that the test expects to be valid, failing the test (rather than
    /// force-unwrapping) if it isn't.
    private func parse(_ string: String) throws -> SemanticVersion {
        try XCTUnwrap(SemanticVersion(string))
    }

    func testParsesPlainVersion() {
        let version = SemanticVersion("1.2.3")
        XCTAssertEqual(version?.components, [1, 2, 3])
    }

    func testStripsLeadingV() {
        XCTAssertEqual(SemanticVersion("v0.2.0")?.components, [0, 2, 0])
        XCTAssertEqual(SemanticVersion("V10.0")?.components, [10, 0])
    }

    func testIgnoresPreReleaseAndBuildMetadata() {
        XCTAssertEqual(SemanticVersion("1.4.0-beta.2")?.components, [1, 4, 0])
        XCTAssertEqual(SemanticVersion("2.0.0+sha.abc")?.components, [2, 0, 0])
    }

    func testRejectsNonNumeric() {
        XCTAssertNil(SemanticVersion("latest"))
        XCTAssertNil(SemanticVersion("v"))
        XCTAssertNil(SemanticVersion(""))
    }

    func testOrdering() throws {
        XCTAssertTrue(try parse("0.1.0") < parse("0.2.0"))
        XCTAssertTrue(try parse("0.9.0") < parse("1.0.0"))
        XCTAssertTrue(try parse("1.0.0") < parse("1.0.1"))
        XCTAssertFalse(try parse("2.0.0") < parse("1.9.9"))
    }

    func testEqualityTreatsMissingTrailingComponentsAsZero() throws {
        XCTAssertEqual(SemanticVersion("1.2"), SemanticVersion("1.2.0"))
        XCTAssertFalse(try parse("1.2.1") < parse("1.2"))
        XCTAssertTrue(try parse("1.2") < parse("1.2.1"))
    }

    func testNewerReleaseBeatsCurrentBuild() throws {
        // The exact comparison UpdateChecker performs.
        XCTAssertTrue(try parse("0.1.0") < parse("v0.2.0"))
    }

    func testNormalizedDropsLeadingVAndMetadata() {
        XCTAssertEqual(SemanticVersion("v0.2.0")?.normalized, "0.2.0")
        XCTAssertEqual(SemanticVersion("1.4.0-beta.2")?.normalized, "1.4.0")
    }
}
