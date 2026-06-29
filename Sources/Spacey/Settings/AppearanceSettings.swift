import Combine
import Foundation

/// How the always-visible menu-bar item renders.
enum MenuBarStyle: String, CaseIterable, Identifiable {
    /// Glyph plus the current Space's name/number (the default).
    case iconAndName
    /// Just the name/number, no glyph.
    case nameOnly
    /// Just the glyph, for the most compact menu bar.
    case iconOnly

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .iconAndName: return "Icon and name"
        case .nameOnly: return "Name only"
        case .iconOnly: return "Icon only"
        }
    }

    var showsIcon: Bool {
        self != .nameOnly
    }

    var showsName: Bool {
        self != .iconOnly
    }
}

/// Persisted look-and-feel preferences. Currently just the menu-bar item style, but a
/// natural home for future appearance options. Backed by `UserDefaults` with an
/// injectable suite to match the other stores and keep it testable.
@MainActor
final class AppearanceSettings: ObservableObject {
    @Published var menuBarStyle: MenuBarStyle {
        didSet { defaults.set(menuBarStyle.rawValue, forKey: Self.styleKey) }
    }

    /// Whether to infer an icon and color from a Space's name when the user hasn't picked
    /// one explicitly. On by default; turning it off restores plain, neutral defaults.
    @Published var suggestIcons: Bool {
        didSet { defaults.set(suggestIcons, forKey: Self.suggestKey) }
    }

    private static let styleKey = "com.getspacey.appearance.menuBarStyle"
    private static let suggestKey = "com.getspacey.appearance.suggestIcons"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.styleKey).flatMap(MenuBarStyle.init)
        menuBarStyle = stored ?? .iconAndName
        suggestIcons = defaults.object(forKey: Self.suggestKey) as? Bool ?? true
    }
}
