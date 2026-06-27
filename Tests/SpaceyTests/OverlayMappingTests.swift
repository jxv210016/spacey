import XCTest
@testable import Spacey

final class OverlayMappingTests: XCTestCase {
    private func thumb(_ index: Int) -> SpaceThumbnail {
        SpaceThumbnail(
            index: index,
            title: "Desktop \(index)",
            frame: CGRect(x: index * 100, y: 40, width: 80, height: 60)
        )
    }

    private func space(_ identity: String, index: Int) -> Space {
        Space(
            uuid: identity,
            managedID: UInt64(index),
            displayID: "Main",
            indexOnDisplay: index,
            globalIndex: index,
            isCurrent: false,
            type: 0
        )
    }

    func testMapsThumbnailToNamedSpaceByPosition() {
        let thumbs = [thumb(1), thumb(2), thumb(3)]
        let spaces = [space("a", index: 1), space("b", index: 2), space("c", index: 3)]
        let names = ["b": SpaceName(label: "Work", colorHex: "#FF453A")]
        let labels = OverlayMapping.labels(thumbnails: thumbs, spaces: spaces) { names[$0] }

        XCTAssertEqual(labels.count, 1)
        XCTAssertEqual(labels.first?.id, 2)
        XCTAssertEqual(labels.first?.text, "Work")
        XCTAssertEqual(labels.first?.colorHex, "#FF453A")
        XCTAssertEqual(labels.first?.frame, thumb(2).frame)
    }

    func testSkipsUnnamedAndBlankSpaces() {
        let thumbs = [thumb(1), thumb(2)]
        let spaces = [space("a", index: 1), space("b", index: 2)]
        let names = ["a": SpaceName(label: "   ")] // whitespace -> no label
        let labels = OverlayMapping.labels(thumbnails: thumbs, spaces: spaces) { names[$0] }
        XCTAssertTrue(labels.isEmpty)
    }

    func testIgnoresThumbnailIndexOutOfRange() {
        // More thumbnails than known spaces (e.g. an "add desktop" leftover or stale read).
        let thumbs = [thumb(1), thumb(2), thumb(3)]
        let spaces = [space("a", index: 1)]
        let names = ["a": SpaceName(label: "Only")]
        let labels = OverlayMapping.labels(thumbnails: thumbs, spaces: spaces) { names[$0] }
        XCTAssertEqual(labels.map(\.text), ["Only"])
    }

    func testPreservesIconAndColor() {
        let thumbs = [thumb(1)]
        let spaces = [space("a", index: 1)]
        let names = ["a": SpaceName(label: "Code", symbol: "hammer", colorHex: "#0A84FF")]
        let label = OverlayMapping.labels(thumbnails: thumbs, spaces: spaces) { names[$0] }.first
        XCTAssertEqual(label?.symbol, "hammer")
        XCTAssertEqual(label?.colorHex, "#0A84FF")
    }
}
