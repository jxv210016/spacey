import Combine
import Foundation

/// Observable state for the Quick Switcher palette: the live query, the current
/// selection, and the filtered results derived from them. Key handling lives in the
/// presenter (which owns the `NSEvent` monitor); this type holds the state and the
/// small selection/query mutations the presenter drives, keeping the logic testable.
@MainActor
final class QuickSwitcherModel: ObservableObject {
    /// The type-to-filter text.
    @Published var query = "" { didSet { clampSelection() } }
    /// Index into `results` of the highlighted row.
    @Published private(set) var selection = 0

    private var entries: [QuickSwitcherEntry] = []

    /// Entries matching the current query, in order.
    var results: [QuickSwitcherEntry] {
        QuickSwitcherFilter.filter(entries, query: query)
    }

    /// The currently highlighted entry, if any.
    var selectedEntry: QuickSwitcherEntry? {
        let results = self.results
        return results.indices.contains(selection) ? results[selection] : nil
    }

    /// Load a fresh entry set and reset the query, highlighting the current Space so
    /// Return on an untouched palette is a harmless no-op rather than a surprise jump.
    func reset(entries: [QuickSwitcherEntry]) {
        self.entries = entries
        query = ""
        selection = entries.firstIndex { $0.isCurrent } ?? 0
    }

    /// Move the highlight by `delta`, wrapping around the ends of the result list.
    func moveSelection(by delta: Int) {
        let count = results.count
        guard count > 0 else { return }
        selection = ((selection + delta) % count + count) % count
    }

    /// Append a typed character to the query.
    func appendToQuery(_ string: String) {
        query.append(string)
    }

    /// Delete the last character of the query (backspace).
    func deleteBackward() {
        guard !query.isEmpty else { return }
        query.removeLast()
    }

    /// The entry at a 1-based position in the current results, for numeric quick-jump.
    func entry(forNumber number: Int) -> QuickSwitcherEntry? {
        let index = number - 1
        let results = self.results
        return results.indices.contains(index) ? results[index] : nil
    }

    private func clampSelection() {
        let count = results.count
        selection = count == 0 ? 0 : min(selection, count - 1)
    }
}
