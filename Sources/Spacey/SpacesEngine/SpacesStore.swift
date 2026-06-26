import AppKit
import Combine

/// Observable source of truth for the current Spaces layout.
///
/// Refreshes from SkyLight whenever `SpaceChangeMonitor` reports a change — space
/// switches, structural plist rewrites, and display reconfiguration.
@MainActor
final class SpacesStore: ObservableObject {
    @Published private(set) var displays: [DisplaySpaces] = []
    @Published private(set) var activeDisplayID: String?
    @Published private(set) var isAvailable: Bool = SkyLightBridge.isAvailable

    private var monitor: SpaceChangeMonitor?

    init(startMonitoring: Bool = true) {
        refresh()
        guard startMonitoring else { return }
        let monitor = SpaceChangeMonitor { [weak self] in self?.refresh() }
        monitor.start()
        self.monitor = monitor
    }

    // No deinit needed: releasing `monitor` triggers SpaceChangeMonitor.deinit
    // (removes observers) and, transitively, SpacesPlistWatcher.deinit (cancels the
    // dispatch source).

    func refresh() {
        isAvailable = SkyLightBridge.isAvailable
        displays = SpacesReader.snapshot()
        activeDisplayID = SkyLightBridge.activeDisplayIdentifier()
    }

    /// All spaces across every display, in order.
    var allSpaces: [Space] {
        displays.allSpaces
    }

    /// The space the user is currently looking at (active display aware).
    var currentSpace: Space? {
        displays.currentSpace(activeDisplayID: activeDisplayID)
    }
}
