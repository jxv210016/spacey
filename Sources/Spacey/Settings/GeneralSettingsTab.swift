import SwiftUI

/// General preferences: launch-at-login and a way to replay first-run setup.
struct GeneralSettingsTab: View {
    @ObservedObject var launchAtLogin: LaunchAtLogin
    let onReplaySetup: () -> Void

    var body: some View {
        Form {
            Section {
                Toggle("Launch Spacey at login", isOn: launchBinding)
                if let error = launchAtLogin.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Spacey will start automatically and stay in the menu bar after you log in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Replay setup…", action: onReplaySetup)
            } footer: {
                Text("Walk through the welcome and permission steps again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { launchAtLogin.refresh() }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            set: { launchAtLogin.setEnabled($0) }
        )
    }
}
