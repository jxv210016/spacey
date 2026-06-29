import SwiftUI

/// The app's Settings window. A left-hand sidebar (`NavigationSplitView`) selects between
/// panes shown on the right — the modern macOS System Settings shape — replacing the old
/// top tab bar. The window is resizable; each pane fills the detail area responsively.
struct SettingsView: View {
    @ObservedObject var model: AppModel

    /// The selectable panes, in sidebar order. Each carries its own label and tint so the
    /// sidebar and the pane header stay in sync.
    enum Pane: String, CaseIterable, Identifiable {
        case general, appearance, shortcuts, missionControl, permissions, updates, about

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general: return "General"
            case .appearance: return "Appearance"
            case .shortcuts: return "Shortcuts"
            case .missionControl: return "Mission Control"
            case .permissions: return "Permissions"
            case .updates: return "Updates"
            case .about: return "About"
            }
        }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .shortcuts: return "command"
            case .missionControl: return "rectangle.3.group"
            case .permissions: return "lock.shield"
            case .updates: return "arrow.triangle.2.circlepath"
            case .about: return "info.circle"
            }
        }

        var tint: Color {
            switch self {
            case .general: return .gray
            case .appearance: return .indigo
            case .shortcuts: return .pink
            case .missionControl: return .blue
            case .permissions: return .orange
            case .updates: return .green
            case .about: return .secondary
            }
        }
    }

    @State private var selection: Pane? = .general

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $selection) { pane in
                Label {
                    Text(pane.title)
                } icon: {
                    Image(systemName: pane.icon)
                        .foregroundStyle(pane.tint)
                }
                .tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 204, max: 240)
        } detail: {
            detail
                .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 680, idealWidth: 740, minHeight: 460, idealHeight: 500)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .general {
        case .general:
            GeneralSettingsTab(launchAtLogin: model.launchAtLogin, onReplaySetup: model.showOnboarding)
        case .appearance:
            AppearanceSettingsTab(appearance: model.appearance)
        case .shortcuts:
            ShortcutsSettingsTab(bindings: model.hotkeys)
        case .missionControl:
            MissionControlSettingsTab(labeler: model.labeler, accessibility: model.accessibility)
        case .permissions:
            PermissionsSettingsTab(accessibility: model.accessibility)
        case .updates:
            UpdatesSettingsTab(updates: model.updates)
        case .about:
            AboutSettingsTab(onReplaySetup: model.showOnboarding)
        }
    }
}
