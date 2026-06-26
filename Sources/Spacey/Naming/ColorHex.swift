import SwiftUI

/// Parsing and formatting for `#RRGGBB` color strings, kept separate from any view
/// so the conversion is unit-testable (SwiftUI `Color` itself is not comparable).
enum ColorHex {
    /// 0...1 RGB components.
    struct RGB: Equatable {
        let red: Double
        let green: Double
        let blue: Double
    }

    /// Parse `#RRGGBB` / `RRGGBB` into RGB components. Returns `nil` if malformed.
    static func rgb(from hex: String) -> RGB? {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        guard string.count == 6, let value = UInt32(string, radix: 16) else { return nil }
        return RGB(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// Normalize any accepted form to canonical uppercase `#RRGGBB`, or `nil`.
    static func normalized(_ hex: String) -> String? {
        guard let rgb = rgb(from: hex) else { return nil }
        return String(
            format: "#%02X%02X%02X",
            Int((rgb.red * 255).rounded()),
            Int((rgb.green * 255).rounded()),
            Int((rgb.blue * 255).rounded())
        )
    }
}

extension Color {
    /// Create a `Color` from a `#RRGGBB` string, or `nil` if it can't be parsed.
    init?(hex: String) {
        guard let rgb = ColorHex.rgb(from: hex) else { return nil }
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

/// Curated palette + SF Symbol choices offered in the naming UI.
enum SpacePalette {
    /// `(name, hex)` swatches.
    static let colors: [(name: String, hex: String)] = [
        ("Red", "#FF453A"),
        ("Orange", "#FF9F0A"),
        ("Yellow", "#FFD60A"),
        ("Green", "#32D74B"),
        ("Teal", "#64D2FF"),
        ("Blue", "#0A84FF"),
        ("Purple", "#BF5AF2"),
        ("Pink", "#FF375F"),
        ("Gray", "#8E8E93")
    ]

    /// SF Symbol names offered for a Space icon.
    static let symbols: [String] = [
        "square.grid.2x2",
        "hammer",
        "terminal",
        "envelope",
        "message",
        "globe",
        "music.note",
        "paintbrush",
        "book",
        "gamecontroller",
        "chart.bar",
        "folder"
    ]
}
