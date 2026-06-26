import Foundation

/// Pure selection helpers over a parsed snapshot. Kept free of any private-API or
/// system dependency so they can be unit-tested directly.
extension [DisplaySpaces] {
    /// Every space across all displays, in order.
    var allSpaces: [Space] {
        flatMap(\.spaces)
    }

    /// The space the user is currently looking at.
    ///
    /// Prefers the current space of the active display (the one with the menu bar);
    /// falls back to the first current space found if the active display is unknown
    /// or has no flagged current space.
    func currentSpace(activeDisplayID: String?) -> Space? {
        if let activeDisplayID,
           let display = first(where: { $0.displayID == activeDisplayID }),
           let current = display.spaces.first(where: \.isCurrent) {
            return current
        }
        return allSpaces.first(where: \.isCurrent)
    }

    /// The display matching `id`, or `nil`.
    func display(withID id: String?) -> DisplaySpaces? {
        guard let id else { return nil }
        return first { $0.displayID == id }
    }
}
