import XCTest
@testable import Spacey

/// Integration tests for the filesystem watcher against a real temp file, exercising
/// both in-place writes and atomic rewrites (the case that defeats a naive watcher).
final class SpacesPlistWatcherTests: XCTestCase {
    private var tempURL: URL!

    override func setUpWithError() throws {
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("spacey-watch-\(UUID().uuidString).plist")
        try Data("v0".utf8).write(to: tempURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testFiresOnInPlaceWrite() {
        let changed = expectation(description: "watcher fired")
        changed.assertForOverFulfill = false
        let watcher = SpacesPlistWatcher(url: tempURL, debounce: .milliseconds(20)) {
            changed.fulfill()
        }
        watcher.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            try? Data("v1".utf8).write(to: self.tempURL)
        }

        wait(for: [changed], timeout: 3)
        watcher.stop()
    }

    func testReArmsAndFiresAfterAtomicRewrite() {
        // `.atomic` writes to a temp file and renames over the target — the original
        // inode is replaced, exactly like macOS rewriting the spaces plist. A watcher
        // that doesn't re-arm would miss every change after the first.
        let firstChange = expectation(description: "first change")
        firstChange.assertForOverFulfill = false
        let secondChange = expectation(description: "second change after re-arm")
        secondChange.assertForOverFulfill = false

        var fireCount = 0
        let watcher = SpacesPlistWatcher(url: tempURL, debounce: .milliseconds(20)) {
            fireCount += 1
            if fireCount == 1 { firstChange.fulfill() }
            if fireCount >= 2 { secondChange.fulfill() }
        }
        watcher.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            try? Data("v1".utf8).write(to: self.tempURL, options: .atomic)
        }
        wait(for: [firstChange], timeout: 3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? Data("v2".utf8).write(to: self.tempURL, options: .atomic)
        }
        wait(for: [secondChange], timeout: 3)
        watcher.stop()
    }

    func testStopPreventsFurtherCallbacks() {
        let inverted = expectation(description: "should not fire after stop")
        inverted.isInverted = true
        let watcher = SpacesPlistWatcher(url: tempURL, debounce: .milliseconds(20)) {
            inverted.fulfill()
        }
        watcher.start()
        watcher.stop()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? Data("v1".utf8).write(to: self.tempURL)
        }
        wait(for: [inverted], timeout: 1)
    }
}
