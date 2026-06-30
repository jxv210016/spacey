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
    /// 0-based disambiguator among the **empty-UUID** Spaces on this display, assigned
    /// in display order by the parser. Almost always `0` (there is normally exactly one
    /// empty-UUID original login Space). It exists only to break a pathological collision:
    /// if a display ever reports two empty-UUID Spaces, the first keeps the canonical
    /// `primary@<displayID>` key (so existing saved names still load) and any extra ones
    /// get a distinct deterministic key instead of silently sharing one name record.
    /// Ignored for Spaces that have a real UUID.
    var primaryOrdinal: Int = 0

    var id: String {
        identity
    }

    /// A stable, always-non-empty key for storing custom names against.
    /// Prefers the UUID; falls back to a per-display marker for the original
    /// Space (which has an empty UUID). The fallback intentionally keys on
    /// `displayID` (not position), so the primary Space's name follows desktop
    /// reorders and survives reboots. A second empty-UUID Space on the same
    /// display (a defensive, normally-impossible case) is disambiguated by
    /// `primaryOrdinal` so it does not collide with the primary's name record.
    var identity: String {
        guard uuid.isEmpty else { return uuid }
        return primaryOrdinal == 0
            ? "primary@\(displayID)"
            : "primary@\(displayID)#\(primaryOrdinal)"
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
