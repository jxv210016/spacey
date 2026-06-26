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

    /// The SF Symbol to show: the custom icon if set, otherwise a type-appropriate default.
    static func symbol(for space: Space, name: SpaceName?) -> String {
        if let symbol = name?.symbol, !symbol.isEmpty { return symbol }
        return space.isUserSpace ? "square.dashed" : "rectangle.inset.filled"
    }

    /// Whether the user has given this Space any custom identity.
    static func isNamed(_ name: SpaceName?) -> Bool {
        guard let name else { return false }
        return !name.isEmpty
    }
}
