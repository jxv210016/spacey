import SwiftUI

/// Mission Control preferences: the master toggle for showing custom Space names inside
/// Mission Control, plus a short explanation.
struct MissionControlSettingsTab: View {
    @ObservedObject var labeler: MissionControlLabeler
    @ObservedObject var accessibility: AccessibilityMonitor

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Toggle("", isOn: $labeler.isEnabled).labelsHidden()
                } label: {
                    Text("Show names in Mission Control")
                    Text("Overlay your desktop names on the Spaces bar while Mission Control is open.")
                }
            }

            if labeler.isEnabled, !accessibility.isTrusted {
                Section {
                    Label(
                        "Accessibility access is required. Grant it in the Permissions tab.",
                        systemImage: "lock.shield"
                    )
                    .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }
}
