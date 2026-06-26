import SwiftUI

@main
struct SpaceyApp: App {
    @StateObject private var store = SpacesStore()
    @StateObject private var names = SpaceNamesStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store, names: names)
        } label: {
            // Menu-bar title: the current Space's custom name, or its number.
            let current = store.currentSpace
            Image(systemName: SpaceDisplay.symbol(for: current ?? .placeholder, name: currentName))
            Text(SpaceDisplay.menuBarTitle(for: current, name: currentName))
        }
        .menuBarExtraStyle(.window)
    }

    private var currentName: SpaceName? {
        guard let current = store.currentSpace else { return nil }
        return names.name(for: current.identity)
    }
}

private extension Space {
    /// Neutral stand-in used only for the menu-bar icon when no space is current.
    static let placeholder = Space(
        uuid: "",
        managedID: 0,
        displayID: "",
        indexOnDisplay: 0,
        globalIndex: 0,
        isCurrent: false,
        type: 0
    )
}
