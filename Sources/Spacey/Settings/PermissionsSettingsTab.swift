import SwiftUI

/// Permissions pane: live Accessibility status with a grant button and a plain-language
/// explanation of why the access is needed. Status updates the instant the user changes
/// it in System Settings (driven by `AccessibilityMonitor`).
struct PermissionsSettingsTab: View {
    @ObservedObject var accessibility: AccessibilityMonitor

    private var hasAccessibility: Bool {
        accessibility.isTrusted
    }

    var body: some View {
        SettingsPage(
            title: "Permissions",
            subtitle: "Access Spacey needs to do its job.",
            systemImage: "lock.shield.fill",
            tint: .orange
        ) {
            Section {
                SettingsRow(
                    title: "Accessibility",
                    subtitle: "Lets Spacey read Mission Control and switch Spaces. "
                        + "It never reads your documents or keystrokes."
                ) {
                    if hasAccessibility {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .labelStyle(.titleAndIcon)
                    } else {
                        Button("Grant…") { accessibility.requestAccess() }
                    }
                }
            }
        }
    }
}
