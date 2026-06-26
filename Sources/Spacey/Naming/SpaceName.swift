import Foundation

/// User-assigned metadata for a Space, persisted against `Space.identity`.
struct SpaceName: Codable, Hashable {
    /// Custom label. May be empty if the user only set an icon/color.
    var label: String
    /// SF Symbol name, if chosen.
    var symbol: String?
    /// Color as `#RRGGBB`, if chosen.
    var colorHex: String?

    init(label: String = "", symbol: String? = nil, colorHex: String? = nil) {
        self.label = label
        self.symbol = symbol
        self.colorHex = colorHex
    }

    /// A trimmed label, or `nil` if blank.
    var trimmedLabel: String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Whether this carries no user information and can be dropped from storage.
    var isEmpty: Bool {
        trimmedLabel == nil && symbol == nil && colorHex == nil
    }
}
