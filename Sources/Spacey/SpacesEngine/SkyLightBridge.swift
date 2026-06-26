import Foundation

/// Thin, isolated wrapper around the private SkyLight (formerly CoreGraphics "CGS")
/// Spaces APIs.
///
/// This is the **only** type in the app that touches private symbols. Every symbol
/// is resolved at runtime with `dlsym` and invoked through a typed `@convention(c)`
/// closure, so a renamed or removed symbol degrades to `nil` instead of preventing
/// the app from launching. If Apple renames a symbol in a future macOS release, this
/// is the single file that needs to change.
///
/// Read-only enumeration (`SLSCopyManagedDisplaySpaces`) has been stable from macOS
/// Mojave through Sequoia and requires no SIP changes, no special entitlements, and
/// no code injection.
enum SkyLightBridge {
    /// SkyLight lives in the dyld shared cache; `dlopen` by path still resolves it.
    private static let handle: UnsafeMutableRawPointer? =
        dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)

    private typealias MainConnectionIDFn = @convention(c) () -> Int32
    private typealias CopyManagedDisplaySpacesFn = @convention(c) (Int32) -> Unmanaged<CFArray>?

    private static func symbol<T>(_ name: String, as _: T.Type) -> T? {
        guard let handle, let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }

    /// Prefer the modern `SLS*` names, fall back to the legacy `CGS*` shims.
    private static let mainConnectionID: MainConnectionIDFn? =
        symbol("SLSMainConnectionID", as: MainConnectionIDFn.self)
            ?? symbol("CGSMainConnectionID", as: MainConnectionIDFn.self)

    private static let copyManagedDisplaySpaces: CopyManagedDisplaySpacesFn? =
        symbol("SLSCopyManagedDisplaySpaces", as: CopyManagedDisplaySpacesFn.self)
            ?? symbol("CGSCopyManagedDisplaySpaces", as: CopyManagedDisplaySpacesFn.self)

    /// Whether the read path is usable on this macOS build.
    static var isAvailable: Bool {
        mainConnectionID != nil && copyManagedDisplaySpaces != nil
    }

    /// The WindowServer connection id for this process, or `nil` if unavailable.
    static func connectionID() -> Int32? {
        mainConnectionID?()
    }

    /// Raw per-display Spaces configuration as Swift dictionaries, or `nil` if the
    /// private API could not be reached. See `SpacesReader` for parsing.
    ///
    /// Each element describes one display and contains:
    ///   - `"Display Identifier"`: display UUID string (or `"Main"`)
    ///   - `"Current Space"`: the active space dict for that display
    ///   - `"Spaces"`: ordered array of space dicts (`"uuid"`, `"ManagedSpaceID"`/`"id64"`, `"type"`)
    static func managedDisplaySpaces() -> [[String: Any]]? {
        guard let cid = mainConnectionID?(), let copy = copyManagedDisplaySpaces else { return nil }
        guard let array = copy(cid)?.takeRetainedValue() as? [[String: Any]] else { return nil }
        return array
    }
}
