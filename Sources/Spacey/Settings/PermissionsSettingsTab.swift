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
        Form {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(hasAccessibility ? Color.green : Color.orange)
                    Text(hasAccessibility ? "Accessibility access granted" : "Accessibility access needed")
                        .fontWeight(.medium)
                    Spacer()
                    if !hasAccessibility {
                        Button("Grant Accessibility…") { accessibility.requestAccess() }
                    }
                }
            } footer: {
                Text(
                    "Accessibility lets Spacey read Mission Control to place your names "
                        + "correctly, and drive System Events to switch Spaces. Spacey never "
                        + "reads your documents or keystrokes."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
