import SwiftUI

/// About pane: app identity, version, a one-line description, and project links.
struct AboutSettingsTab: View {
    let onReplaySetup: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 8)
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            VStack(spacing: 4) {
                Text(AppInfo.name).font(.title.weight(.bold))
                Text("Version \(AppInfo.version) (\(AppInfo.build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Text(AppInfo.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                if let url = AppInfo.repositoryURL {
                    Link("GitHub Repository", destination: url)
                }
                Text("·").foregroundStyle(.secondary)
                Text(AppInfo.license).foregroundStyle(.secondary)
            }
            .font(.callout)

            Button("Replay setup…", action: onReplaySetup)
                .padding(.top, 4)

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
