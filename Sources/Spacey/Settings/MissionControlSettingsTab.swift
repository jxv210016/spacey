import SwiftUI

/// Mission Control preferences: the master toggle for showing custom Space names inside
/// Mission Control, plus a short explanation.
struct MissionControlSettingsTab: View {
    @ObservedObject var labeler: MissionControlLabeler

    var body: some View {
        Form {
            Section {
                Toggle("Show names in Mission Control", isOn: $labeler.isEnabled)
            } footer: {
                Text(
                    "When enabled, Spacey overlays your custom desktop names on the "
                        + "Spaces bar whenever Mission Control is open."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if labeler.isEnabled, !labeler.hasAccessibility {
                Section {
                    Label(
                        "Accessibility access is required for this feature. "
                            + "Grant it in the Permissions tab.",
                        systemImage: "lock.shield"
                    )
                    .font(.callout)
                    .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }
}
