import SwiftUI

/// Mission Control preferences: the master toggle for showing custom Space names inside
/// Mission Control, plus a short explanation and a permission reminder when needed.
struct MissionControlSettingsTab: View {
    @ObservedObject var labeler: MissionControlLabeler
    @ObservedObject var accessibility: AccessibilityMonitor

    var body: some View {
        SettingsPage(
            title: "Mission Control",
            subtitle: "Show your Space names inside Mission Control.",
            systemImage: "rectangle.3.group.fill",
            tint: .blue
        ) {
            Section {
                SettingsRow(
                    title: "Show names in Mission Control",
                    subtitle: "Overlay your desktop names on the Spaces bar while Mission Control is open."
                ) {
                    Toggle("", isOn: $labeler.isEnabled).labelsHidden()
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
    }
}
