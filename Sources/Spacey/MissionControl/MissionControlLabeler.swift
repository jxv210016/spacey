import AppKit
import ApplicationServices
import Combine

/// Orchestrates the Mission Control name overlay: when MC opens, read the Spaces-Bar
/// thumbnails, map them to custom names, and show labels; hide when MC closes.
@MainActor
final class MissionControlLabeler: ObservableObject {
    /// User toggle (persisted). Default on — the headline feature.
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled { overlay.hide() }
        }
    }

    private static let enabledKey = "com.getspacey.missionControlLabels.enabled"

    private let store: SpacesStore
    private let names: SpaceNamesStore
    private let appearance: AppearanceSettings
    private let defaults: UserDefaults
    private let overlay = MissionControlOverlayWindow()
    private var observer: MissionControlObserver?
    private var pollTimer: Timer?

    init(
        store: SpacesStore,
        names: SpaceNamesStore,
        appearance: AppearanceSettings,
        defaults: UserDefaults = .standard
    ) {
        self.store = store
        self.names = names
        self.appearance = appearance
        self.defaults = defaults
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Whether the app currently has Accessibility permission (required).
    var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func start() {
        guard observer == nil else { return }
        let observer = MissionControlObserver { [weak self] isOpen in
            // Delivered on the main run loop by the AX callback.
            MainActor.assumeIsolated { self?.handle(isOpen: isOpen) }
        }
        observer.start()
        self.observer = observer
    }

    /// Re-arm the observer after Accessibility is granted at runtime — a registration
    /// made while untrusted won't deliver notifications.
    func restartObserver() {
        observer?.stop()
        observer = nil
        start()
    }

    private func handle(isOpen: Bool) {
        guard isEnabled, isOpen else { stopPolling(); overlay.hide(); return }
        startPolling()
    }

    /// While MC is open, the Spaces Bar collapses (thumbnails off-screen) and expands
    /// on hover. Poll so labels track the live thumbnail positions and appear only
    /// when the bar is expanded on screen.
    private func startPolling() {
        stopPolling()
        presentLabels()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.presentLabels() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func presentLabels() {
        guard isEnabled, let screen = NSScreen.main else { return }
        let thumbnails = SpacesBarReader.read()
        let spaces = store.displays.first?.spaces ?? store.allSpaces
        let positioned = positionedThumbnails(thumbnails, screen: screen)
        let labels = OverlayMapping.labels(
            thumbnails: positioned,
            spaces: spaces,
            suggestions: appearance.suggestIcons,
            name: { [names] identity in names.name(for: identity) }
        )
        overlay.show(labels: labels, on: screen)
    }

    /// Resolve thumbnail frames to on-screen positions for the current Spaces Bar state.
    ///
    /// - Expanded: the pill/thumbnail frames are already correct; keep the ones on screen.
    /// - Collapsed: the pills report off-screen (negative) Y, but their X is correct and
    ///   the bar *group* sits on screen as a short top strip. Rebuild each frame from the
    ///   pill's X dropped into that strip so labels appear under the collapsed pills.
    /// - Otherwise (bar off screen / mid-animation): draw nothing.
    private func positionedThumbnails(_ thumbnails: [SpaceThumbnail], screen: NSScreen) -> [SpaceThumbnail] {
        func onScreen(_ midY: CGFloat) -> Bool {
            midY > 0 && midY < screen.frame.height
        }

        let expanded = thumbnails.filter { onScreen($0.frame.midY) }
        if !expanded.isEmpty { return expanded }

        guard let bar = SpacesBarReader.barFrame(), onScreen(bar.midY) else { return [] }
        return thumbnails.map { thumbnail in
            SpaceThumbnail(
                index: thumbnail.index,
                title: thumbnail.title,
                frame: CGRect(x: thumbnail.frame.minX, y: bar.minY, width: thumbnail.frame.width, height: bar.height)
            )
        }
    }
}
