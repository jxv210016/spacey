import SwiftUI

/// Updates pane: shows the running version, a "Check Now" action, the latest-check result,
/// and a toggle for automatic checks. When a newer release exists it offers a download
/// link. Backed by `UpdateChecker`.
struct UpdatesSettingsTab: View {
    @ObservedObject var updates: UpdateChecker

    var body: some View {
        SettingsPage(
            title: "Updates",
            subtitle: "Keep Spacey up to date.",
            systemImage: "arrow.triangle.2.circlepath",
            tint: .green
        ) {
            Section {
                SettingsRow(title: "Spacey \(AppInfo.version)", subtitle: statusText) {
                    Button {
                        Task { await updates.checkNow() }
                    } label: {
                        if updates.status == .checking {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Check Now")
                        }
                    }
                    .disabled(updates.status == .checking)
                }

                if case let .updateAvailable(version, url) = updates.status {
                    SettingsRow(
                        title: "Version \(version) is available",
                        subtitle: "A newer version of Spacey is ready to download."
                    ) {
                        Link(destination: url) {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                    }
                }
            }

            Section {
                SettingsRow(
                    title: "Check for updates automatically",
                    subtitle: "Spacey checks GitHub for new releases when it launches."
                ) {
                    Toggle("", isOn: $updates.automaticallyChecks).labelsHidden()
                }
                if let url = AppInfo.releasesPageURL {
                    SettingsRow(
                        title: "All releases",
                        subtitle: "Browse past versions and release notes on GitHub."
                    ) {
                        Link("Open…", destination: url)
                    }
                }
            }
        }
    }

    /// A one-line description of the latest check, including when it ran.
    private var statusText: String {
        switch updates.status {
        case .idle:
            return "Check GitHub for the latest release."
        case .checking:
            return "Checking for updates…"
        case .upToDate:
            return "You’re up to date." + lastCheckedSuffix
        case .updateAvailable:
            return "An update is available." + lastCheckedSuffix
        case let .failed(message):
            return "Couldn’t check for updates. \(message)"
        }
    }

    private var lastCheckedSuffix: String {
        guard let lastChecked = updates.lastChecked else { return "" }
        let formatted = lastChecked.formatted(date: .abbreviated, time: .shortened)
        return " Last checked \(formatted)."
    }
}
