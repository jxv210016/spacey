import AppKit
import Combine

/// Observable source of truth for the current Spaces layout.
///
/// Phase 0: refreshes from SkyLight on `activeSpaceDidChangeNotification`. A future
/// phase adds the `com.apple.spaces.plist` `.delete` watch for changes the
/// notification misses (e.g. adding/removing spaces, some fullscreen transitions).
@MainActor
final class SpacesStore: ObservableObject {
    @Published private(set) var displays: [DisplaySpaces] = []
    @Published private(set) var isAvailable: Bool = SkyLightBridge.isAvailable

    private var spaceChangeObserver: NSObjectProtocol?

    init() {
        refresh()
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    deinit {
        if let spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceChangeObserver)
        }
    }

    func refresh() {
        isAvailable = SkyLightBridge.isAvailable
        displays = SpacesReader.snapshot()
    }

    /// All spaces across every display, in order.
    var allSpaces: [Space] {
        displays.flatMap(\.spaces)
    }

    /// The active space on the main display, if any.
    var currentSpace: Space? {
        allSpaces.first(where: \.isCurrent)
    }
}
