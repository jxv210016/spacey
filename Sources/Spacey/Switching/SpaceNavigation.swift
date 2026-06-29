import Foundation

/// Pure index arithmetic for relative Space navigation, free of any system/AppKit
/// dependency so it is directly unit-testable. The side-effecting step lives in
/// `SpaceSwitcher`; this just decides *where* to go.
enum SpaceNavigation {
    /// The 1-based target index when stepping `delta` Spaces from `currentIndex` within
    /// a display holding `count` Spaces. Returns `nil` when the step would fall outside
    /// the display (we don't wrap — stepping off the end is a no-op).
    static func cycleTarget(currentIndex: Int, count: Int, delta: Int) -> Int? {
        let target = currentIndex + delta
        guard target >= 1, target <= count else { return nil }
        return target
    }

    /// The single-step Mission Control arrow key code to move one Space *toward* `target`
    /// from the current 1-based index: `124` (⌃→, move right) when the target is higher,
    /// `123` (⌃←, move left) when lower, `nil` when already there. Direction is recomputed
    /// each step so an overshoot self-corrects.
    static func stepKeyCode(from current: Int, to target: Int) -> Int? {
        if target > current { return 124 }
        if target < current { return 123 }
        return nil
    }
}

/// Tracks the previously active Space so a hotkey can toggle back to it.
///
/// Records the *identity* (stable key) rather than a `Space` snapshot, because indices
/// drift as macOS reorders desktops — callers re-resolve the current index from the
/// live store before navigating.
@MainActor
final class PreviousSpaceTracker {
    private(set) var previousIdentity: String?
    private var currentIdentity: String?

    /// Feed the latest current Space. When it differs from the last one seen, the prior
    /// Space becomes "previous". Nil current Spaces (e.g. a fullscreen transition with no
    /// flagged desktop) are ignored so they don't clobber the toggle target.
    func record(current: Space?) {
        guard let current else { return }
        if let currentIdentity, currentIdentity != current.identity {
            previousIdentity = currentIdentity
        }
        currentIdentity = current.identity
    }
}
