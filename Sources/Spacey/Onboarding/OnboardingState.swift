import Combine
import Foundation

/// Tracks whether the first-run onboarding has been completed, persisted to
/// `UserDefaults` so it survives launches. Backed by an injectable suite to mirror the
/// store pattern used elsewhere and keep the logic unit-testable.
@MainActor
final class OnboardingState: ObservableObject {
    @Published private(set) var hasCompletedOnboarding: Bool

    private let defaults: UserDefaults
    private static let key = "com.getspacey.hasCompletedOnboarding"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Self.key)
    }

    /// Whether onboarding should be shown on this launch.
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// Mark onboarding finished (called by the "Get Started" button).
    func complete() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: Self.key)
    }

    /// Forget completion so the flow can be replayed from Settings.
    func reset() {
        hasCompletedOnboarding = false
        defaults.set(false, forKey: Self.key)
    }
}
