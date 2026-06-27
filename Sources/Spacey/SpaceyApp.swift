import SwiftUI

@main
struct SpaceyApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                store: model.spaces,
                names: model.names,
                labeler: model.labeler,
                accessibility: model.accessibility
            )
        } label: {
            MenuBarLabel(store: model.spaces, names: model.names)
                // The menu-bar label renders at launch, giving us a reliable hook to
                // present first-run onboarding once the app is up.
                .onAppear { model.presentOnboardingIfNeeded() }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
