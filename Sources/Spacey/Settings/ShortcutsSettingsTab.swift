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
                ForEach(generalActions) { recorderRow($0) }
            } footer: {
                Text("Shortcuts work system-wide. Switching uses the built-in Mission Control "
                    + "Control-Arrow shortcuts, so those must stay enabled (see Permissions).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(jumpActions) { recorderRow($0) }
            } header: {
                Text("Jump to desktop")
            } footer: {
                Text("Default ⌃⌥1–9. A shortcut does nothing if that desktop doesn’t exist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func recorderRow(_ action: HotkeyAction) -> some View {
        SettingsRow(title: action.title, subtitle: action.subtitle) {
            KeyComboRecorder(
                combo: bindings.combo(for: action),
                onRecord: { bindings.set($0, for: action) },
                onClear: { bindings.clear(action) }
            )
        }
    }

    private var generalActions: [HotkeyAction] {
        HotkeyAction.allCases.filter { $0.targetDesktopNumber == nil }
    }

    private var jumpActions: [HotkeyAction] {
        HotkeyAction.allCases
            .filter { $0.targetDesktopNumber != nil }
            .sorted { ($0.targetDesktopNumber ?? 0) < ($1.targetDesktopNumber ?? 0) }
    }
}
