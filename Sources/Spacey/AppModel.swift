import Combine
import Foundation

/// Root object owning the app's stores and the Mission Control labeler, so they share
/// a single lifecycle and can reference each other.
@MainActor
final class AppModel: ObservableObject {
    let spaces: SpacesStore
    let names: SpaceNamesStore
    let labeler: MissionControlLabeler
    let launchAtLogin: LaunchAtLogin
    let onboarding: OnboardingState
    let appearance: AppearanceSettings
    let updates: UpdateChecker
    let hotkeys: HotkeyBindings
    let accessibility = AccessibilityMonitor()

    private let hotkeyManager = HotkeyManager()
    private let quickSwitcher: QuickSwitcherPresenter
    private let previousSpace = PreviousSpaceTracker()
    private let onboardingPresenter = OnboardingPresenter()
    private let settingsPresenter = SettingsPresenter()
    private var cancellables = Set<AnyCancellable>()

    init() {
        let spaces = SpacesStore()
        let names = SpaceNamesStore()
        let appearance = AppearanceSettings()
        self.spaces = spaces
        self.names = names
        self.appearance = appearance
        labeler = MissionControlLabeler(store: spaces, names: names, appearance: appearance)
        launchAtLogin = LaunchAtLogin()
        onboarding = OnboardingState()
        let updates = UpdateChecker()
        self.updates = updates
        let hotkeys = HotkeyBindings()
        self.hotkeys = hotkeys
        quickSwitcher = QuickSwitcherPresenter(store: spaces, names: names, appearance: appearance)

        labeler.start()
        accessibility.start()
        AppActivation.observeWindowClosures()

        // Check for a newer release in the background on launch (if the user opted in).
        Task { await updates.checkAutomaticallyIfEnabled() }

        // When Accessibility is granted at runtime, re-arm the Mission Control
        // observer so labels work immediately, without relaunching.
        accessibility.$isTrusted
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in self?.labeler.restartObserver() }
            .store(in: &cancellables)

        // Route fired hotkeys to their actions, and (re-)register whenever the bindings
        // change. `$bindings` emits its current value on subscribe, so this also performs
        // the initial registration on launch.
        hotkeyManager.onAction = { [weak self] action in self?.perform(action) }
        hotkeys.$bindings
            .removeDuplicates()
            .sink { [weak self] bindings in self?.hotkeyManager.update(bindings: bindings) }
            .store(in: &cancellables)

        // Track the previously active Space so the "Previous Space" hotkey can toggle back.
        spaces.$displays
            .combineLatest(spaces.$activeDisplayID)
            .sink { [weak self] displays, activeDisplayID in
                self?.previousSpace.record(current: displays.currentSpace(activeDisplayID: activeDisplayID))
            }
            .store(in: &cancellables)
    }

    // MARK: - Hotkey actions

    private func perform(_ action: HotkeyAction) {
        switch action {
        case .toggleQuickSwitcher: quickSwitcher.toggle()
        case .previousSpace: jumpToPreviousSpace()
        case .cycleNext: cycle(delta: 1)
        case .cyclePrevious: cycle(delta: -1)
        default:
            if let number = action.targetDesktopNumber { jumpToDesktop(number) }
        }
    }

    /// Jump straight to the Nth (1-based) Space on the active display. A no-op if that
    /// desktop doesn't exist.
    private func jumpToDesktop(_ number: Int) {
        let snapshot = SpacesReader.snapshot()
        guard let display = activeDisplay(in: snapshot),
              let current = display.spaces.first(where: { $0.isCurrent }),
              number >= 1, number <= display.spaces.count
        else { return }
        SpaceSwitcher.move(toIndex: number, fromIndex: current.indexOnDisplay, displayCount: snapshot.count)
    }

    /// Step one Space left/right on the active display (no wrap).
    private func cycle(delta: Int) {
        let snapshot = SpacesReader.snapshot()
        guard let display = activeDisplay(in: snapshot),
              let current = display.spaces.first(where: { $0.isCurrent }),
              let target = SpaceNavigation.cycleTarget(
                  currentIndex: current.indexOnDisplay,
                  count: display.spaces.count,
                  delta: delta
              )
        else { return }
        SpaceSwitcher.move(toIndex: target, fromIndex: current.indexOnDisplay, displayCount: snapshot.count)
    }

    /// Toggle back to the previously active Space, re-resolving its current index.
    private func jumpToPreviousSpace() {
        let snapshot = SpacesReader.snapshot()
        guard let identity = previousSpace.previousIdentity,
              let target = snapshot.flatMap(\.spaces).first(where: { $0.identity == identity }),
              !target.isCurrent,
              let display = snapshot.first(where: { $0.displayID == target.displayID }),
              let current = display.spaces.first(where: { $0.isCurrent })
        else { return }
        SpaceSwitcher.move(
            toIndex: target.indexOnDisplay,
            fromIndex: current.indexOnDisplay,
            displayCount: snapshot.count
        )
    }

    /// The active display from a fresh SkyLight snapshot. Reading live here (rather than
    /// from the `@Published` store, which lags a beat behind a switch) keeps back-to-back
    /// jumps from computing a relative step off a stale "current" index.
    private func activeDisplay(in snapshot: [DisplaySpaces]) -> DisplaySpaces? {
        snapshot.first { $0.displayID == spaces.activeDisplayID } ?? snapshot.first
    }

    /// Show onboarding on first launch only.
    func presentOnboardingIfNeeded() {
        guard onboarding.shouldShowOnboarding else { return }
        showOnboarding()
    }

    /// Open (or re-open) the onboarding flow; used at first launch and "Replay setup…".
    func showOnboarding() {
        onboardingPresenter.show(state: onboarding, accessibility: accessibility)
    }

    /// Open the Settings window.
    func showSettings() {
        settingsPresenter.show(model: self)
    }
}
