import Foundation

/// A flattened, display-ready snapshot of one Space for the Quick Switcher. It captures
/// everything the palette needs to render and to navigate, so the view layer never has
/// to reach back into the stores while the palette is open.
struct QuickSwitcherEntry: Identifiable, Equatable {
    /// `Space.identity` — stable across reboots/reorders.
    let id: String
    /// What to show: the custom label or the positional fallback ("Space 2").
    let title: String
    /// SF Symbol to show alongside the title.
    let symbol: String
    /// `#RRGGBB` accent, if the Space has a color.
    let colorHex: String?
    /// 1-based position across all displays — the badge number shown on the row.
    let number: Int
    /// Whether this is the Space the user is currently on.
    let isCurrent: Bool
    /// Navigation coordinates (re-resolved against the live store at switch time).
    let displayID: String
    let indexOnDisplay: Int
}

extension QuickSwitcherEntry {
    /// Build the ordered entry list from the current Spaces + names.
    @MainActor
    static func entries(store: SpacesStore, names: SpaceNamesStore, suggestions: Bool = true) -> [QuickSwitcherEntry] {
        store.allSpaces.map { space in
            let name = names.name(for: space.identity)
            return QuickSwitcherEntry(
                id: space.identity,
                title: SpaceDisplay.title(for: space, name: name),
                symbol: SpaceDisplay.symbol(for: space, name: name, suggestions: suggestions),
                colorHex: SpaceDisplay.colorHex(for: space, name: name, suggestions: suggestions),
                number: space.globalIndex,
                isCurrent: space.isCurrent,
                displayID: space.displayID,
                indexOnDisplay: space.indexOnDisplay
            )
        }
    }
}

/// Pure, case-insensitive substring filtering for the palette. Separated out so the
/// match behaviour is unit-testable without any view or store.
enum QuickSwitcherFilter {
    static func filter(_ entries: [QuickSwitcherEntry], query: String) -> [QuickSwitcherEntry] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return entries }
        return entries.filter { $0.title.lowercased().contains(needle) }
    }
}
