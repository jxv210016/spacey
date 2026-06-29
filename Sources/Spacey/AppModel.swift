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
        self.spaces = spaces
        self.names = names
        labeler = MissionControlLabeler(store: spaces, names: names)
        launchAtLogin = LaunchAtLogin()
        onboarding = OnboardingState()
        appearance = AppearanceSettings()
        let updates = UpdateChecker()
        self.updates = updates
        let hotkeys = HotkeyBindings()
        self.hotkeys = hotkeys
        quickSwitcher = QuickSwitcherPresenter(store: spaces, names: names)

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
        }
    }

    /// Step one Space left/right on the active display (no wrap).
    private func cycle(delta: Int) {
        guard let current = spaces.currentSpace,
              let display = spaces.displays.first(where: { $0.displayID == current.displayID }),
              let target = SpaceNavigation.cycleTarget(
                  currentIndex: current.indexOnDisplay,
                  count: display.spaces.count,
                  delta: delta
              )
        else { return }
        SpaceSwitcher.navigate(fromIndex: current.indexOnDisplay, toIndex: target)
    }

    /// Toggle back to the previously active Space, re-resolving its current index.
    private func jumpToPreviousSpace() {
        guard let identity = previousSpace.previousIdentity,
              let target = spaces.allSpaces.first(where: { $0.identity == identity }),
              !target.isCurrent,
              let display = spaces.displays.first(where: { $0.displayID == target.displayID }),
              let current = display.spaces.first(where: { $0.isCurrent })
        else { return }
        SpaceSwitcher.navigate(fromIndex: current.indexOnDisplay, toIndex: target.indexOnDisplay)
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
