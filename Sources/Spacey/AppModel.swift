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
    let accessibility = AccessibilityMonitor()

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

        labeler.start()
        accessibility.start()
        AppActivation.observeWindowClosures()

        // When Accessibility is granted at runtime, re-arm the Mission Control
        // observer so labels work immediately, without relaunching.
        accessibility.$isTrusted
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in self?.labeler.restartObserver() }
            .store(in: &cancellables)
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
