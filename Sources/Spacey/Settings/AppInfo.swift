import Foundation

/// Small read-only facade over the app's bundle metadata and project links, so the
/// Settings and Onboarding UIs share a single source of truth.
enum AppInfo {
    /// Marketing version, e.g. "0.1.0". Falls back to a placeholder in unusual hosts.
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
    }

    /// Build number, e.g. "1".
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    static let name = "Spacey"

    static let tagline = "Name your desktops, switch by name, and see those names in Mission Control."

    static let repositoryURL = URL(string: "https://github.com/jxv210016/spacey")

    /// GitHub "latest release" API endpoint, used by `UpdateChecker`.
    static let latestReleaseAPIURL = URL(string: "https://api.github.com/repos/jxv210016/spacey/releases/latest")

    /// Human-facing releases page, linked from the Updates pane.
    static let releasesPageURL = URL(string: "https://github.com/jxv210016/spacey/releases")

    static let license = "MIT License"

    static let copyright = "© 2026 Spacey contributors"
}
