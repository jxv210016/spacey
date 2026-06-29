import Foundation

/// A tolerant semantic-version value used to compare the running build against the
/// latest GitHub release. Accepts a leading `v` (e.g. `v0.2.0`) and ignores any
/// pre-release/build metadata after `-` or `+`. Pure and dependency-free so it is
/// directly unit-testable.
struct SemanticVersion: Comparable, CustomStringConvertible {
    /// Numeric release components, most-significant first (e.g. `[0, 2, 0]`).
    let components: [Int]
    /// The original string, preserved for display.
    let raw: String

    /// Parse a version string, or `nil` if it carries no numeric components.
    init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        var core = trimmed
        if core.first == "v" || core.first == "V" { core.removeFirst() }
        // Drop pre-release (`-beta.1`) and build (`+sha`) metadata.
        core = core.split(separator: "-", maxSplits: 1).first.map(String.init) ?? core
        core = core.split(separator: "+", maxSplits: 1).first.map(String.init) ?? core

        let parsed = core.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard !parsed.isEmpty, parsed.allSatisfy({ $0 != nil }) else { return nil }

        components = parsed.compactMap { $0 }
        raw = trimmed
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0 ..< count where lhs.part(index) != rhs.part(index) {
            return lhs.part(index) < rhs.part(index)
        }
        return false
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        return (0 ..< count).allSatisfy { lhs.part($0) == rhs.part($0) }
    }

    /// Component at `index`, treating missing trailing positions as `0` so `1.2`
    /// compares equal to `1.2.0`.
    private func part(_ index: Int) -> Int {
        index < components.count ? components[index] : 0
    }

    /// A clean, display-ready version string built from the numeric components
    /// (e.g. `0.2.0`). Unlike `raw`, it drops any leading `v`/`V` and metadata, so
    /// callers can prefix their own label without producing "v" duplication.
    var normalized: String {
        components.map(String.init).joined(separator: ".")
    }

    var description: String {
        raw
    }
}
