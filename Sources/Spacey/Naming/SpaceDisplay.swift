import Foundation

/// Pure resolution of what to *show* for a Space given its optional custom name.
/// Free of any view/system dependency so it is directly unit-testable.
enum SpaceDisplay {
    /// The custom label if set, otherwise a positional fallback like `Space 2`.
    static func title(for space: Space, name: SpaceName?) -> String {
        name?.trimmedLabel ?? "Space \(space.indexOnDisplay)"
    }

    /// A short menu-bar title: the custom label (truncated) if set, else the number.
    static func menuBarTitle(for space: Space?, name: SpaceName?, maxLength: Int = 14) -> String {
        guard let space else { return "–" }
        if let label = name?.trimmedLabel {
            return label.count > maxLength ? String(label.prefix(maxLength - 1)) + "…" : label
        }
        return "\(space.globalIndex)"
    }

    /// The SF Symbol to show. Resolution order: the user's explicit pick, then a
    /// suggestion inferred from the custom name (when `suggestions` is on), then a
    /// type-appropriate default.
    static func symbol(for space: Space, name: SpaceName?, suggestions: Bool = true) -> String {
        if let symbol = name?.symbol, !symbol.isEmpty { return symbol }
        if suggestions, let label = name?.trimmedLabel, let suggested = IconSuggestion.symbol(forLabel: label) {
            return suggested
        }
        return space.isUserSpace ? "square.dashed" : "rectangle.inset.filled"
    }

    /// The symbol to show *inside the color dot*: the explicit pick or a name-based
    /// suggestion, but never the positional default — an unstyled Space keeps a plain dot.
    static func markSymbol(for _: Space, name: SpaceName?, suggestions: Bool = true) -> String? {
        if let symbol = name?.symbol, !symbol.isEmpty { return symbol }
        if suggestions, let label = name?.trimmedLabel { return IconSuggestion.symbol(forLabel: label) }
        return nil
    }

    /// The `#RRGGBB` accent to use. Resolution order: the user's explicit color, then a
    /// suggestion inferred from the custom name (when `suggestions` is on), else `nil`
    /// (no color / outlined dot).
    static func colorHex(for _: Space, name: SpaceName?, suggestions: Bool = true) -> String? {
        if let hex = name?.colorHex, !hex.isEmpty { return hex }
        if suggestions, let label = name?.trimmedLabel { return IconSuggestion.colorHex(forLabel: label) }
        return nil
    }

    /// Whether the user has given this Space any custom identity.
    static func isNamed(_ name: SpaceName?) -> Bool {
        guard let name else { return false }
        return !name.isEmpty
    }
}
