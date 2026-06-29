import SwiftUI

/// About pane: app identity, version, a one-line description, project links, and a way to
/// replay first-run setup. A centered identity splash rather than a grouped form, so it
/// reads as the app's "home" page.
struct AboutSettingsTab: View {
    let onReplaySetup: () -> Void

    var body: some View {
        // A ScrollView (like the Form-based panes) so this pane reserves the same
        // titlebar safe-area inset — otherwise switching to About nudges the whole
        // split view, including the sidebar, upward.
        ScrollView {
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 44)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.windowBackground)
    }

    private var content: some View {
        VStack(spacing: 16) {
            appIcon
                .frame(width: 84, height: 84)

            VStack(spacing: 4) {
                Text(AppInfo.name)
                    .font(.title.weight(.bold))
                Text("Version \(AppInfo.version) (\(AppInfo.build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text(AppInfo.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            HStack(spacing: 10) {
                if let url = AppInfo.repositoryURL {
                    Link("GitHub", destination: url)
                }
                Text("·").foregroundStyle(.tertiary)
                Text(AppInfo.license).foregroundStyle(.secondary)
            }
            .font(.callout)

            Button("Replay setup…", action: onReplaySetup)
                .padding(.top, 2)

            Text(AppInfo.copyright)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 12)
        }
    }

    /// The bundle's app icon, falling back to the SF Symbol used elsewhere.
    @ViewBuilder
    private var appIcon: some View {
        if let nsImage = NSImage(named: "AppIcon") {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "square.grid.2x2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.tint)
        }
    }
}
