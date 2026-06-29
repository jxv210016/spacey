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
    struct Rule {
        let keywords: [String]
        let symbol: String
        let colorHex: String
    }

    static let rules: [Rule] = [
        Rule(keywords: ["mail", "email", "inbox", "gmail", "outlook"], symbol: "envelope", colorHex: "#0A84FF"),
        Rule(keywords: ["terminal", "shell", "bash", "console", "ssh"], symbol: "terminal", colorHex: "#32D74B"),
        Rule(keywords: ["code", "coding", "dev", "develop", "programming", "program", "xcode", "vscode", "git", "build"], symbol: "chevron.left.forwardslash.chevron.right", colorHex: "#32D74B"),
        Rule(keywords: ["meeting", "meet", "zoom", "call", "standup", "webex"], symbol: "video", colorHex: "#0A84FF"),
        Rule(keywords: ["chat", "slack", "discord", "messages", "message", "imessage", "teams"], symbol: "message", colorHex: "#64D2FF"),
        Rule(keywords: ["music", "spotify", "song", "songs", "audio", "itunes", "podcast"], symbol: "music.note", colorHex: "#FF375F"),
        Rule(keywords: ["design", "figma", "sketch", "draw", "drawing", "art", "creative"], symbol: "paintbrush.pointed", colorHex: "#BF5AF2"),
        Rule(keywords: ["game", "gaming", "games", "steam", "play"], symbol: "gamecontroller", colorHex: "#FF453A"),
        Rule(keywords: ["web", "browser", "browse", "safari", "chrome", "firefox", "internet"], symbol: "globe", colorHex: "#64D2FF"),
        Rule(keywords: ["finance", "money", "budget", "bank", "banking", "invest", "stock", "stocks", "trading", "crypto"], symbol: "chart.line.uptrend.xyaxis", colorHex: "#32D74B"),
        Rule(keywords: ["video", "youtube", "movie", "movies", "film", "netflix", "watch", "stream", "streaming"], symbol: "play.rectangle", colorHex: "#FF453A"),
        Rule(keywords: ["photo", "photos", "image", "images", "picture", "pictures", "gallery"], symbol: "photo", colorHex: "#FFD60A"),
        Rule(keywords: ["read", "reading", "book", "books", "library", "notes", "note", "writing", "write", "docs", "doc"], symbol: "book", colorHex: "#FF9F0A"),
        Rule(keywords: ["calendar", "schedule", "agenda", "planner", "plan"], symbol: "calendar", colorHex: "#FF453A"),
        Rule(keywords: ["shop", "shopping", "store", "cart", "amazon", "buy"], symbol: "cart", colorHex: "#FF9F0A"),
        Rule(keywords: ["health", "fitness", "gym", "workout", "run", "running", "exercise"], symbol: "heart", colorHex: "#FF375F"),
        Rule(keywords: ["travel", "trip", "flight", "vacation", "holiday"], symbol: "airplane", colorHex: "#64D2FF"),
        Rule(keywords: ["school", "study", "studying", "class", "learn", "learning", "course", "research"], symbol: "graduationcap", colorHex: "#0A84FF"),
        Rule(keywords: ["social", "twitter", "instagram", "facebook", "reddit"], symbol: "person.2", colorHex: "#FF375F"),
        Rule(keywords: ["cloud", "aws", "server", "servers", "deploy", "infra"], symbol: "cloud", colorHex: "#64D2FF"),
        Rule(keywords: ["ai", "ml", "llm", "gpt", "chatgpt", "claude"], symbol: "sparkles", colorHex: "#BF5AF2"),
        Rule(keywords: ["file", "files", "folder", "folders", "storage", "drive"], symbol: "folder", colorHex: "#FFD60A"),
        Rule(keywords: ["work", "working", "job", "office", "client", "clients"], symbol: "hammer", colorHex: "#FF9F0A"),
        Rule(keywords: ["home", "personal", "life", "house"], symbol: "house", colorHex: "#64D2FF")
    ]

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
