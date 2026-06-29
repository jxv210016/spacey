import SwiftUI

/// General preferences: launch-at-login and a way to replay first-run setup.
struct GeneralSettingsTab: View {
    @ObservedObject var launchAtLogin: LaunchAtLogin
    let onReplaySetup: () -> Void

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Toggle("", isOn: launchBinding).labelsHidden()
                } label: {
                    Text("Launch at login")
                    Text("Start Spacey automatically and keep it in the menu bar.")
                }
                if let error = launchAtLogin.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent {
                    Button("Replay…", action: onReplaySetup)
                } label: {
                    Text("First-run setup")
                    Text("Walk through the welcome and permission steps again.")
                }
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
