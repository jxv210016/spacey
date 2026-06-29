import SwiftUI

/// The always-visible menu-bar item. Lives as its own view observing the stores so it
/// updates live when the active Space changes or a name/color is edited — an inline
/// label in the App scene would only refresh when `AppModel` itself changed.
struct MenuBarLabel: View {
    @ObservedObject var store: SpacesStore
    @ObservedObject var names: SpaceNamesStore
    @ObservedObject var appearance: AppearanceSettings

    var body: some View {
        let current = store.currentSpace
        let record = current.flatMap { names.name(for: $0.identity) }
        let style = appearance.menuBarStyle

        HStack(spacing: 4) {
            if style.showsIcon {
                Image(systemName: glyph(for: current, record: record))
            }
            if style.showsName {
                Text(SpaceDisplay.menuBarTitle(for: current, name: record))
            }
        }
    }

    private func glyph(for space: Space?, record: SpaceName?) -> String {
        // Route through SpaceDisplay so the menu bar shares the same explicit →
        // suggested → default resolution (and fallback glyph) as the Spaces list.
        guard let space else { return "rectangle.3.group" }
        return SpaceDisplay.symbol(for: space, name: record, suggestions: appearance.suggestIcons)
    }
}
