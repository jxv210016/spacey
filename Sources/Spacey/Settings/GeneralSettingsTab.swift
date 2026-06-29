import SwiftUI

/// General preferences: launch-at-login and a way to replay first-run setup.
struct GeneralSettingsTab: View {
    @ObservedObject var launchAtLogin: LaunchAtLogin
    let onReplaySetup: () -> Void

    var body: some View {
        SettingsPage(
            title: "General",
            subtitle: "How Spacey starts and behaves.",
            systemImage: "gearshape.fill",
            tint: .gray
        ) {
            Section {
                SettingsRow(
                    title: "Launch at login",
                    subtitle: "Start Spacey automatically and keep it in the menu bar."
                ) {
                    Toggle("", isOn: launchBinding).labelsHidden()
                }
                if let error = launchAtLogin.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                SettingsRow(
                    title: "First-run setup",
                    subtitle: "Walk through the welcome and permission steps again."
                ) {
                    Button("Replay…", action: onReplaySetup)
                }
            }
        }
        .onAppear { launchAtLogin.refresh() }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            set: { launchAtLogin.setEnabled($0) }
        )
    }
}
