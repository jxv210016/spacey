import Foundation

/// A single macOS Space (virtual desktop) on a particular display.
struct Space: Identifiable, Hashable {
    /// Per-space UUID. Stable across reboots and macOS auto-reordering when present —
    /// **but the original login Space reports an empty UUID** (only `managedID`
    /// identifies it). Use `identity` for a key that is always non-empty.
    let uuid: String
    /// Opaque 64-bit handle (`ManagedSpaceID`/`id64`) the SkyLight functions take.
    /// Assigned per login session — not stable across reboots.
    let managedID: UInt64
    /// UUID of the display this space belongs to (or `"Main"`).
    let displayID: String
    /// 1-based position within its display's ordered space list (the user-visible number).
    let indexOnDisplay: Int
    /// 1-based position across all displays.
    let globalIndex: Int
    /// Whether this is the currently active space on its display.
    let isCurrent: Bool
    /// Raw space type. Values drift across macOS builds — runtime-probe before trusting.
    /// `0` is a normal user space; fullscreen/tiled vary.
    let type: Int

    var id: String {
        identity
    }

    /// A stable, always-non-empty key for storing custom names against.
    /// Prefers the UUID; falls back to a per-display marker for the original
    /// Space (which has an empty UUID).
    var identity: String {
        uuid.isEmpty ? "primary@\(displayID)" : uuid
    }

    /// Whether this is a regular user desktop (vs fullscreen/system).
    var isUserSpace: Bool {
        type == 0
    }
}

/// The ordered Spaces belonging to one display.
struct DisplaySpaces: Hashable {
    let displayID: String
    let spaces: [Space]
    /// `managedID` of the active space on this display.
    let currentSpaceID: UInt64?
}
