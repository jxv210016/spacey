import Combine
import ServiceManagement

/// Pure mapping from a `SMAppService.Status` to a simple on/off state, split out so it
/// can be unit-tested without touching the live login-item registration.
enum LaunchAtLoginStatus {
    static func isEnabled(for status: SMAppService.Status) -> Bool {
        status == .enabled
    }
}

/// Thin, observable wrapper over `SMAppService.mainApp` (ServiceManagement, macOS 13+),
/// used to register/unregister Spacey as a login item with no external dependency.
/// Errors are surfaced via `lastError` rather than thrown, so the UI stays in sync with
/// the real system state after any attempt.
@MainActor
final class LaunchAtLogin: ObservableObject {
    /// Reflects the live system registration state.
    @Published private(set) var isEnabled: Bool = false

    /// Human-readable description of the most recent failure, if any.
    @Published private(set) var lastError: String?

    init() {
        isEnabled = Self.systemEnabled()
    }

    /// Re-read the live status (e.g. when the Settings window reappears).
    func refresh() {
        isEnabled = Self.systemEnabled()
    }

    /// Register or unregister the login item, then resync `isEnabled` with reality.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    private static func systemEnabled() -> Bool {
        LaunchAtLoginStatus.isEnabled(for: SMAppService.mainApp.status)
    }
}
