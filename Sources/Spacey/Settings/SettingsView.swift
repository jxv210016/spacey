import SwiftUI

/// The app's Settings window, presented via the SwiftUI `Settings` scene and openable
/// with ⌘, or the menu's "Settings…" item. A tabbed layout keeps each concern on its
/// own pane, matching the standard macOS settings shape.
struct SettingsView: View {
    @ObservedObject var model: AppModel

    private enum Tab: Hashable {
        case general, missionControl, permissions, about
    }

    @State private var selection: Tab = .general

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsTab(launchAtLogin: model.launchAtLogin, onReplaySetup: model.showOnboarding)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)

            MissionControlSettingsTab(labeler: model.labeler, accessibility: model.accessibility)
                .tabItem { Label("Mission Control", systemImage: "rectangle.3.group") }
                .tag(Tab.missionControl)

            PermissionsSettingsTab(accessibility: model.accessibility)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
                .tag(Tab.permissions)

            AboutSettingsTab(onReplaySetup: model.showOnboarding)
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(Tab.about)
        }
        .frame(width: 460, height: 300)
    }
}
