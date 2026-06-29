import Foundation

/// Infers a sensible SF Symbol and accent color from a Space's name, so a freshly
/// named "Mail" Space picks up an envelope and a blue dot without the user touching
/// the icon picker. Pure and case-insensitive, so it's directly unit-testable and can
/// feed every surface (menu bar, rows, Quick Switcher, Mission Control) identically.
///
/// This is only ever a *default*: an explicit user pick always overrides the
/// suggestion (see `SpaceDisplay`), and an unnamed Space gets no suggestion at all.
enum IconSuggestion {
    /// A keyword → (symbol, color) rule. The first rule with a keyword contained in
    /// the (lowercased) label wins, so order from most- to least-specific on overlap.
    ///
    /// Keywords are kept reasonably distinctive (≥3 chars, no ultra-generic fragments
    /// like "ai"/"art"/"run") because matching is substring-based: a short token would
    /// false-match inside unrelated words (e.g. "art" in "startup").
    struct Rule {
        let keywords: [String]
        let symbol: String
        let colorHex: String

        /// `keywords` is given as a space-separated list to keep the table compact.
        init(keywords: String, symbol: String, colorHex: String) {
            self.keywords = keywords.split(separator: " ").map(String.init)
            self.symbol = symbol
            self.colorHex = colorHex
        }
    }

    /// The match table. Defined at file scope (below) so this enum stays focused on
    /// behavior rather than data.
    static let rules = iconSuggestionRules

    /// The full matching rule for a label, if any keyword matches.
    static func match(forLabel label: String) -> Rule? {
        let needle = label.lowercased()
        guard !needle.isEmpty else { return nil }
        return rules.first { rule in
            rule.keywords.contains { needle.contains($0) }
        }
    }

    /// Suggested SF Symbol for a label, or `nil` if nothing matches.
    static func symbol(forLabel label: String) -> String? {
        match(forLabel: label)?.symbol
    }

    /// Suggested `#RRGGBB` accent for a label, or `nil` if nothing matches.
    static func colorHex(forLabel label: String) -> String? {
        match(forLabel: label)?.colorHex
    }
}

/// The name→icon/color match table, ordered most- to least-specific: niche/technical
/// categories first so a generic word ("work", "home") can't shadow a precise one
/// ("xcode", "figma").
private let iconSuggestionRules: [IconSuggestion.Rule] = [
    .init(
        keywords: "mail email inbox gmail outlook proton fastmail",
        symbol: "envelope",
        colorHex: "#0A84FF"
    ),
    .init(
        keywords: "terminal shell bash zsh console command iterm ssh tmux",
        symbol: "terminal",
        colorHex: "#32D74B"
    ),
    .init(
        keywords: "code coding dev develop developer programming xcode vscode editor compile",
        symbol: "chevron.left.forwardslash.chevron.right",
        colorHex: "#32D74B"
    ),
    .init(
        keywords: "git github gitlab pull merge commit branch repo repository version",
        symbol: "arrow.triangle.branch",
        colorHex: "#32D74B"
    ),
    .init(
        keywords: "devops deploy docker kubernetes container infra infrastructure jenkins pipeline",
        symbol: "server.rack",
        colorHex: "#5E5CE6"
    ),
    .init(
        keywords: "cloud aws azure gcp serverless lambda hosting",
        symbol: "cloud",
        colorHex: "#64D2FF"
    ),
    .init(
        keywords: "database sql postgres mysql mongo redis query schema",
        symbol: "cylinder.split.1x2",
        colorHex: "#5E5CE6"
    ),
    .init(
        keywords: "data analytics metrics dashboard report reporting bigquery warehouse",
        symbol: "chart.bar",
        colorHex: "#5E5CE6"
    ),
    .init(
        keywords: "bug bugs issue issues ticket tickets jira support helpdesk zendesk triage",
        symbol: "ladybug",
        colorHex: "#FF453A"
    ),
    .init(
        keywords: "test testing qa quality automation cypress unit",
        symbol: "checkmark.seal",
        colorHex: "#30D158"
    ),
    .init(
        keywords: "llm gpt chatgpt claude openai gemini copilot neural artificial",
        symbol: "sparkles",
        colorHex: "#BF5AF2"
    ),
    .init(
        keywords: "security password passwords vault vpn privacy auth secrets keychain firewall",
        symbol: "lock.shield",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "design figma sketch canva drawing creative illustration prototype mockup",
        symbol: "paintbrush.pointed",
        colorHex: "#BF5AF2"
    ),
    .init(
        keywords: "meeting meet zoom standup webex huddle conference sync",
        symbol: "video",
        colorHex: "#0A84FF"
    ),
    .init(
        keywords: "chat slack discord messages message imessage teams telegram whatsapp",
        symbol: "message",
        colorHex: "#64D2FF"
    ),
    .init(
        keywords: "call calls phone dialer facetime voip",
        symbol: "phone",
        colorHex: "#30D158"
    ),
    .init(
        keywords: "music spotify song songs audio itunes soundcloud playlist tunes",
        symbol: "music.note",
        colorHex: "#FF375F"
    ),
    .init(
        keywords: "podcast podcasts episode audiobook",
        symbol: "mic",
        colorHex: "#BF5AF2"
    ),
    .init(
        keywords: "video youtube movie movies film netflix editing premiere finalcut davinci stream streaming",
        symbol: "play.rectangle",
        colorHex: "#FF453A"
    ),
    .init(
        keywords: "photo photos image images picture pictures gallery camera lightroom",
        symbol: "photo",
        colorHex: "#FFD60A"
    ),
    .init(
        keywords: "game gaming games steam playstation xbox nintendo arcade",
        symbol: "gamecontroller",
        colorHex: "#FF453A"
    ),
    .init(
        keywords: "web browser browse safari chrome firefox internet bookmarks",
        symbol: "globe",
        colorHex: "#64D2FF"
    ),
    .init(
        keywords: "crypto bitcoin ethereum blockchain wallet web3 nft defi token",
        symbol: "bitcoinsign.circle",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "finance money budget bank banking invest investing stock stocks trading taxes",
        symbol: "chart.line.uptrend.xyaxis",
        colorHex: "#32D74B"
    ),
    .init(
        keywords: "shop shopping store cart amazon orders ecommerce checkout",
        symbol: "cart",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "office word excel powerpoint pages keynote numbers spreadsheet slides pdf",
        symbol: "doc.text",
        colorHex: "#0A84FF"
    ),
    .init(
        keywords: "notes note notion obsidian journal blog markdown writing scratchpad",
        symbol: "note.text",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "read reading book books library kindle articles",
        symbol: "book",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "tasks task todo kanban trello asana linear board backlog sprint",
        symbol: "checklist",
        colorHex: "#0A84FF"
    ),
    .init(
        keywords: "calendar schedule agenda planner appointments events",
        symbol: "calendar",
        colorHex: "#FF453A"
    ),
    .init(
        keywords: "health fitness gym workout exercise running cycling steps wellness",
        symbol: "heart",
        colorHex: "#FF375F"
    ),
    .init(
        keywords: "food cooking recipe recipes restaurant kitchen meal dinner groceries",
        symbol: "fork.knife",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "travel trip flight flights vacation hotel hotels airbnb itinerary",
        symbol: "airplane",
        colorHex: "#64D2FF"
    ),
    .init(
        keywords: "maps location navigation directions route commute transit",
        symbol: "map",
        colorHex: "#30D158"
    ),
    .init(
        keywords: "weather forecast climate temperature rain",
        symbol: "cloud.sun",
        colorHex: "#64D2FF"
    ),
    .init(
        keywords: "news headlines reuters bloomberg press media journalism",
        symbol: "newspaper",
        colorHex: "#8E8E93"
    ),
    .init(
        keywords: "school study studying class learn learning course homework lecture exam",
        symbol: "graduationcap",
        colorHex: "#0A84FF"
    ),
    .init(
        keywords: "research science lab laboratory paper papers thesis experiment",
        symbol: "flask",
        colorHex: "#5E5CE6"
    ),
    .init(
        keywords: "social twitter instagram facebook reddit tiktok linkedin mastodon threads",
        symbol: "person.2",
        colorHex: "#FF375F"
    ),
    .init(
        keywords: "sports football basketball soccer baseball hockey nba nfl tennis golf",
        symbol: "sportscourt",
        colorHex: "#30D158"
    ),
    .init(
        keywords: "focus zen meditation mindfulness deepwork concentrate",
        symbol: "moon",
        colorHex: "#5E5CE6"
    ),
    .init(
        keywords: "pets pet dog cat animal animals puppy kitten",
        symbol: "pawprint",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "garden plant plants gardening flowers nature outdoor",
        symbol: "leaf",
        colorHex: "#30D158"
    ),
    .init(
        keywords: "car cars auto vehicle tesla driving garage",
        symbol: "car",
        colorHex: "#8E8E93"
    ),
    .init(
        keywords: "settings config configuration admin system preferences setup",
        symbol: "gearshape",
        colorHex: "#8E8E93"
    ),
    .init(
        keywords: "files file folder folders storage drive dropbox documents archive",
        symbol: "folder",
        colorHex: "#FFD60A"
    ),
    .init(
        keywords: "work working job office client clients business career",
        symbol: "hammer",
        colorHex: "#FF9F0A"
    ),
    .init(
        keywords: "home personal life house family household",
        symbol: "house",
        colorHex: "#64D2FF"
    )
]
