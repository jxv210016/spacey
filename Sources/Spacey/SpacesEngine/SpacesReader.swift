import Foundation

/// Turns the raw SkyLight per-display dictionaries into typed `DisplaySpaces`.
///
/// The parsing is split out as a pure function (`parse`) so it can be unit-tested
/// with fixtures without touching the private API.
enum SpacesReader {
    /// Read a live snapshot from SkyLight. Returns an empty array if unavailable.
    static func snapshot() -> [DisplaySpaces] {
        guard let raw = SkyLightBridge.managedDisplaySpaces() else { return [] }
        return parse(raw)
    }

    /// Pure parser over the raw SkyLight dictionary shape. Exposed for testing.
    static func parse(_ displays: [[String: Any]]) -> [DisplaySpaces] {
        var result: [DisplaySpaces] = []
        var globalIndex = 0

        for display in displays {
            let displayID = display["Display Identifier"] as? String ?? "Unknown"
            let currentSpace = display["Current Space"] as? [String: Any]
            // Match the current space by ManagedSpaceID, not UUID: the original login
            // space reports an empty UUID, so UUID matching misses it entirely.
            let currentID = unsigned(currentSpace?["ManagedSpaceID"]) ?? unsigned(currentSpace?["id64"])
            let rawSpaces = display["Spaces"] as? [[String: Any]] ?? []

            var spaces: [Space] = []
            // Count empty-UUID Spaces as we go so a (pathological) second one on the
            // same display gets a distinct deterministic key instead of colliding with
            // the primary Space's name record. See `Space.identity`.
            var emptyUUIDOrdinal = 0
            for (offset, raw) in rawSpaces.enumerated() {
                let uuid = raw["uuid"] as? String ?? ""
                let managedID = unsigned(raw["ManagedSpaceID"])
                    ?? unsigned(raw["id64"])
                    ?? 0
                // -1 sentinel means "unknown type". Note: never coerce a missing
                // value through UInt64.max — `Int(UInt64.max)` traps.
                let type = integer(raw["type"]) ?? -1
                let primaryOrdinal: Int
                if uuid.isEmpty {
                    primaryOrdinal = emptyUUIDOrdinal
                    emptyUUIDOrdinal += 1
                } else {
                    primaryOrdinal = 0
                }
                globalIndex += 1
                spaces.append(
                    Space(
                        uuid: uuid,
                        managedID: managedID,
                        displayID: displayID,
                        indexOnDisplay: offset + 1,
                        globalIndex: globalIndex,
                        isCurrent: currentID != nil && managedID == currentID,
                        type: type,
                        primaryOrdinal: primaryOrdinal
                    )
                )
            }

            result.append(
                DisplaySpaces(displayID: displayID, spaces: spaces, currentSpaceID: currentID)
            )
        }

        return result
    }

    /// Coerce a CoreFoundation/NSNumber-ish value to UInt64 (for space IDs).
    private static func unsigned(_ value: Any?) -> UInt64? {
        if let u = value as? UInt64 { return u }
        if let i = value as? Int { return UInt64(bitPattern: Int64(i)) }
        if let n = value as? NSNumber { return n.uint64Value }
        return nil
    }

    /// Coerce a CoreFoundation/NSNumber-ish value to a signed Int (for space type).
    private static func integer(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }
}
