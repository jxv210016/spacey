import SwiftUI

/// Shortcuts preferences: a recorder per `HotkeyAction` so each global hotkey can be
/// independently assigned or cleared. Edits flow straight into `HotkeyBindings`, which
/// `AppModel` observes to re-register the live Carbon hotkeys.
struct ShortcutsSettingsTab: View {
    @ObservedObject var bindings: HotkeyBindings

    var body: some View {
        SettingsPage(
            title: "Shortcuts",
            subtitle: "Global hotkeys for switching Spaces.",
            systemImage: "command",
            tint: .pink
        ) {
            Section {
                ForEach(HotkeyAction.allCases) { action in
                    SettingsRow(title: action.title, subtitle: action.subtitle) {
                        KeyComboRecorder(
                            combo: bindings.combo(for: action),
                            onRecord: { bindings.set($0, for: action) },
                            onClear: { bindings.clear(action) }
                        )
                    }
                }
            } footer: {
                Text("Shortcuts work system-wide. Switching uses the built-in Mission Control "
                    + "Control-Arrow shortcuts, so those must stay enabled (see Permissions).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
