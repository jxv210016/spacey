import Combine
import Foundation

/// Lightweight, dependency-free update check against the project's GitHub Releases.
///
/// Queries the "latest release" endpoint, compares its tag to the running build with
/// `SemanticVersion`, and surfaces a `status` the Updates pane renders. Spacey is not
/// sandboxed, so an outgoing request needs no entitlement. There is no auto-install —
/// when an update exists we hand the user a download link, in keeping with the app's
/// zero-dependency philosophy.
@MainActor
final class UpdateChecker: ObservableObject {
    /// The outcome of the most recent (or in-flight) check.
    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(version: String, url: URL)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var lastChecked: Date?

    /// Whether Spacey checks for updates on launch. Persisted; on by default.
    @Published var automaticallyChecks: Bool {
        didSet { defaults.set(automaticallyChecks, forKey: Self.autoKey) }
    }

    private static let autoKey = "com.getspacey.updates.automatic"

    private let currentVersion: String
    private let releaseURL: URL?
    private let defaults: UserDefaults
    private let session: URLSession

    init(
        currentVersion: String = AppInfo.version,
        releaseURL: URL? = AppInfo.latestReleaseAPIURL,
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.currentVersion = currentVersion
        self.releaseURL = releaseURL
        self.defaults = defaults
        self.session = session
        automaticallyChecks = defaults.object(forKey: Self.autoKey) as? Bool ?? true
    }

    /// Run a check only if the user has opted into automatic checks (called at launch).
    func checkAutomaticallyIfEnabled() async {
        guard automaticallyChecks else { return }
        await checkNow()
    }

    /// Fetch the latest release and update `status`. Safe to call repeatedly; a check
    /// already in flight is ignored.
    func checkNow() async {
        guard status != .checking else { return }
        guard let releaseURL else {
            status = .failed("Update checks aren’t configured for this build.")
            return
        }

        status = .checking
        do {
            var request = URLRequest(url: releaseURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            // GitHub rejects requests without a User-Agent.
            request.setValue(AppInfo.name, forHTTPHeaderField: "User-Agent")
            request.cachePolicy = .reloadIgnoringLocalCacheData

            let (data, response) = try await session.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            lastChecked = Date()

            // A valid repo with no published releases returns 404 — nothing to update to.
            if code == 404 {
                status = .upToDate
                return
            }
            guard 200..<300 ~= code else {
                status = .failed("GitHub returned an error (\(code)).")
                return
            }

            let release = try JSONDecoder().decode(Release.self, from: data)
            guard let latest = SemanticVersion(release.tagName),
                  let current = SemanticVersion(currentVersion)
            else {
                status = .failed("Couldn’t read the latest version number.")
                return
            }

            if latest > current {
                // Use `normalized` (not `raw`) so the pane doesn't render "Version v0.2.0".
                status = .updateAvailable(version: latest.normalized, url: release.downloadURL)
            } else {
                status = .upToDate
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Wire format

/// The subset of GitHub's release JSON we care about. Hoisted to file scope (rather
/// than nested in `UpdateChecker`) to keep the type nesting shallow.
private struct Release: Decodable {
    let tagName: String
    let htmlURL: URL
    let assets: [ReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }

    /// Prefer a downloadable disk image / archive; fall back to the release page.
    var downloadURL: URL {
        let installable = assets.first { asset in
            let lower = asset.name.lowercased()
            return lower.hasSuffix(".dmg") || lower.hasSuffix(".zip") || lower.hasSuffix(".pkg")
        }
        return installable?.browserDownloadURL ?? htmlURL
    }
}

/// A single downloadable artifact attached to a GitHub release.
private struct ReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
