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

    /// A searchable catalog of SF Symbols offered for a Space icon. `terms` are extra
    /// search keywords beyond the symbol name itself (which is also matched), so typing
    /// "mail" finds `envelope` and "code" finds the chevron symbol.
    static let iconCatalog: [(symbol: String, terms: String)] = [
        ("hammer", "work job tools build"),
        ("briefcase", "work job office business"),
        ("terminal", "code shell console dev"),
        ("chevron.left.forwardslash.chevron.right", "code dev programming xcode"),
        ("envelope", "mail email inbox message"),
        ("message", "chat slack discord text"),
        ("bubble.left.and.bubble.right", "chat conversation talk"),
        ("phone", "call phone contact"),
        ("video", "meeting zoom call meet"),
        ("globe", "web browser internet safari"),
        ("safari", "web browser internet"),
        ("music.note", "music song audio spotify"),
        ("headphones", "music audio podcast listen"),
        ("paintbrush.pointed", "design art draw creative"),
        ("paintpalette", "design art color creative"),
        ("pencil.and.outline", "design sketch draw notes"),
        ("book", "read reading notes docs library"),
        ("text.book.closed", "read book study notes"),
        ("newspaper", "news reading articles"),
        ("graduationcap", "school study learn course"),
        ("gamecontroller", "game gaming play steam"),
        ("chart.line.uptrend.xyaxis", "finance stocks trading growth"),
        ("chart.bar", "stats analytics data chart"),
        ("chart.pie", "stats analytics data"),
        ("dollarsign.circle", "money finance budget bank"),
        ("creditcard", "money payment bank finance"),
        ("cart", "shop shopping store buy"),
        ("bag", "shop shopping store buy"),
        ("folder", "files storage documents drive"),
        ("doc.text", "document file notes text"),
        ("tray.full", "inbox files tasks"),
        ("photo", "photo image picture gallery"),
        ("camera", "photo camera picture"),
        ("play.rectangle", "video youtube movie stream watch"),
        ("film", "movie film video cinema"),
        ("tv", "tv video stream watch"),
        ("calendar", "calendar schedule agenda plan"),
        ("clock", "time schedule clock timer"),
        ("checklist", "tasks todo list productivity"),
        ("list.bullet", "list tasks notes todo"),
        ("person.2", "social people team contacts"),
        ("person.crop.circle", "profile account person"),
        ("heart", "health fitness favorite love"),
        ("figure.run", "fitness run exercise gym health"),
        ("airplane", "travel trip flight vacation"),
        ("map", "map travel location places"),
        ("house", "home personal house"),
        ("building.2", "office work company building"),
        ("cloud", "cloud server aws infra"),
        ("server.rack", "server infra backend"),
        ("externaldrive", "storage drive backup files"),
        ("sparkles", "ai ml gpt claude magic"),
        ("brain", "ai ml ideas thinking"),
        ("lightbulb", "ideas notes inspiration"),
        ("gearshape", "settings config system tools"),
        ("wrench.and.screwdriver", "tools build fix work"),
        ("lock", "security private vault password"),
        ("bell", "notifications alerts reminders"),
        ("flag", "flag priority important"),
        ("star", "favorite star important"),
        ("bookmark", "bookmark save read"),
        ("tag", "tag label category"),
        ("square.grid.2x2", "grid apps general default"),
        ("rectangle.3.group", "spaces desktops general")
    ]
}
