import XCTest
@testable import Spacey

@MainActor
final class SpaceNamesStoreTests: XCTestCase {
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

    func testStartsEmpty() {
        let store = SpaceNamesStore(defaults: defaults)
        XCTAssertNil(store.name(for: "id-1"))
        XCTAssertTrue(store.names.isEmpty)
    }

    func testSetAndGetLabel() {
        let store = SpaceNamesStore(defaults: defaults)
        store.setLabel("Work", for: "id-1")
        XCTAssertEqual(store.name(for: "id-1")?.label, "Work")
    }

    func testSetIconAndColorMergeOntoSameRecord() {
        let store = SpaceNamesStore(defaults: defaults)
        store.setLabel("Work", for: "id-1")
        store.setSymbol("hammer", for: "id-1")
        store.setColorHex("#FF453A", for: "id-1")
        let name = store.name(for: "id-1")
        XCTAssertEqual(name?.label, "Work")
        XCTAssertEqual(name?.symbol, "hammer")
        XCTAssertEqual(name?.colorHex, "#FF453A")
    }

    func testEmptyRecordIsRemovedNotStored() {
        let store = SpaceNamesStore(defaults: defaults)
        store.setLabel("temp", for: "id-1")
        store.setLabel("   ", for: "id-1") // whitespace-only label, no icon/color
        XCTAssertNil(store.name(for: "id-1"))
        XCTAssertTrue(store.names.isEmpty)
    }

    func testClearRemovesRecord() {
        let store = SpaceNamesStore(defaults: defaults)
        store.setLabel("Work", for: "id-1")
        store.clear("id-1")
        XCTAssertNil(store.name(for: "id-1"))
    }

    func testClearingLabelKeepsRecordWhenIconRemains() {
        let store = SpaceNamesStore(defaults: defaults)
        store.setSymbol("hammer", for: "id-1")
        store.setLabel("", for: "id-1")
        XCTAssertEqual(store.name(for: "id-1")?.symbol, "hammer")
        XCTAssertNotNil(store.name(for: "id-1"))
    }

    func testPersistsAcrossStoreInstances() {
        let first = SpaceNamesStore(defaults: defaults)
        first.setLabel("Persisted", for: "id-1")
        first.setColorHex("#0A84FF", for: "id-1")

        let second = SpaceNamesStore(defaults: defaults)
        XCTAssertEqual(second.name(for: "id-1")?.label, "Persisted")
        XCTAssertEqual(second.name(for: "id-1")?.colorHex, "#0A84FF")
    }

    func testNamesAreKeyedIndependently() {
        let store = SpaceNamesStore(defaults: defaults)
        store.setLabel("A", for: "id-1")
        store.setLabel("B", for: "id-2")
        XCTAssertEqual(store.name(for: "id-1")?.label, "A")
        XCTAssertEqual(store.name(for: "id-2")?.label, "B")
    }

    func testCorruptStorageDecodesAsEmpty() {
        defaults.set(Data("not json".utf8), forKey: "com.getspacey.spaceNames.v1")
        let store = SpaceNamesStore(defaults: defaults)
        XCTAssertTrue(store.names.isEmpty)
    }
}
