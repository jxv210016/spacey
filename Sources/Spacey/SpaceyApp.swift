import SwiftUI

@main
struct SpaceyApp: App {
    @StateObject private var store = SpacesStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store)
        } label: {
            // The menu-bar title shows the current space's number for now.
            // A future phase swaps this for the custom name/icon.
            Image(systemName: "rectangle.3.group")
            Text(menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarTitle: String {
        guard let current = store.currentSpace else { return "–" }
        return "\(current.globalIndex)"
    }
}
