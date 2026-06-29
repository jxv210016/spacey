import XCTest
@testable import Spacey

final class SemanticVersionTests: XCTestCase {
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

    func testOrdering() {
        XCTAssertTrue(SemanticVersion("0.1.0")! < SemanticVersion("0.2.0")!)
        XCTAssertTrue(SemanticVersion("0.9.0")! < SemanticVersion("1.0.0")!)
        XCTAssertTrue(SemanticVersion("1.0.0")! < SemanticVersion("1.0.1")!)
        XCTAssertFalse(SemanticVersion("2.0.0")! < SemanticVersion("1.9.9")!)
    }

    func testEqualityTreatsMissingTrailingComponentsAsZero() {
        XCTAssertEqual(SemanticVersion("1.2"), SemanticVersion("1.2.0"))
        XCTAssertFalse(SemanticVersion("1.2.1")! < SemanticVersion("1.2")!)
        XCTAssertTrue(SemanticVersion("1.2")! < SemanticVersion("1.2.1")!)
    }

    func testNewerReleaseBeatsCurrentBuild() {
        // The exact comparison UpdateChecker performs.
        XCTAssertTrue(SemanticVersion("0.1.0")! < SemanticVersion("v0.2.0")!)
    }
}
