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
        let glyph = meaningfulGlyph(for: current, record: record)

        HStack(spacing: 4) {
            if style.showsIcon, let glyph {
                Image(systemName: glyph)
            }
            // Keep something visible: show the name when the style asks for it, or as a
            // fallback when there's no icon (so an icon-only menu bar never collapses to
            // nothing for an unstyled Space).
            if style.showsName || glyph == nil {
                Text(SpaceDisplay.menuBarTitle(for: current, name: record))
            }
        }
    }

    /// The menu-bar glyph, but only when it's *meaningful*: an explicit pick or a
    /// name-based suggestion. An unstyled Space yields `nil` so we render no placeholder
    /// square. With no current Space at all, fall back to the app glyph so the item stays
    /// recognizable.
    private func meaningfulGlyph(for space: Space?, record: SpaceName?) -> String? {
        guard let space else { return "rectangle.3.group" }
        return SpaceDisplay.markSymbol(for: space, name: record, suggestions: appearance.suggestIcons)
    }
}
