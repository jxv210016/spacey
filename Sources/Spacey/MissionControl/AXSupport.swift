import AppKit
import ApplicationServices

/// Minimal Accessibility helpers shared by the Mission Control feature. All reads are
/// best-effort and return empty/`nil` on failure (e.g. missing permission).
enum AXReader {
    static func application(bundleID: String) -> AXUIElement? {
        guard let app = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleID })
        else { return nil }
        return AXUIElementCreateApplication(app.processIdentifier)
    }

    static func dock() -> AXUIElement? {
        application(bundleID: "com.apple.dock")
    }

    static func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: AnyObject?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }

    static func string(_ element: AXUIElement, _ name: String) -> String {
        attribute(element, name) as? String ?? ""
    }

    static func role(_ element: AXUIElement) -> String {
        string(element, kAXRoleAttribute as String)
    }

    static func title(_ element: AXUIElement) -> String {
        string(element, kAXTitleAttribute as String)
    }

    /// AX description (`AXDescription`) — where the add-desktop button keeps its label.
    static func describe(_ element: AXUIElement) -> String {
        string(element, kAXDescriptionAttribute as String)
    }

    static func help(_ element: AXUIElement) -> String {
        string(element, kAXHelpAttribute as String)
    }

    /// Title + description + help, lowercased — a label search that doesn't depend on
    /// which attribute the OS chose to populate.
    static func label(_ element: AXUIElement) -> String {
        [title(element), describe(element), help(element)]
            .joined(separator: " ")
            .lowercased()
    }

    static func children(_ element: AXUIElement) -> [AXUIElement] {
        attribute(element, kAXChildrenAttribute as String) as? [AXUIElement] ?? []
    }

    /// CF types can't be conditionally cast, so validate by type id then cast.
    private static func axValue(_ element: AXUIElement, _ name: String) -> AXValue? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        // swiftlint:disable:next force_cast
        return (value as! AXValue)
    }

    /// On-screen rect (AX coordinates: origin top-left of the main display).
    static func frame(_ element: AXUIElement) -> CGRect? {
        if let axFrame = axValue(element, "AXFrame") {
            var rect = CGRect.zero
            if AXValueGetValue(axFrame, .cgRect, &rect) { return rect }
        }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard let positionValue = axValue(element, kAXPositionAttribute as String),
              AXValueGetValue(positionValue, .cgPoint, &point),
              let sizeValue = axValue(element, kAXSizeAttribute as String),
              AXValueGetValue(sizeValue, .cgSize, &size)
        else { return nil }
        return CGRect(origin: point, size: size)
    }

    /// Depth-first search for the first descendant matching `predicate`.
    static func firstDescendant(
        of root: AXUIElement,
        maxDepth: Int,
        where predicate: (AXUIElement) -> Bool
    ) -> AXUIElement? {
        if predicate(root) { return root }
        guard maxDepth > 0 else { return nil }
        for child in children(root) {
            if let match = firstDescendant(of: child, maxDepth: maxDepth - 1, where: predicate) {
                return match
            }
        }
        return nil
    }

    /// Perform the press (default) action on an element.
    @discardableResult
    static func press(_ element: AXUIElement) -> Bool {
        AXUIElementPerformAction(element, kAXPressAction as CFString) == .success
    }
}

/// One Space thumbnail in the Mission Control "Spaces Bar".
struct SpaceThumbnail: Equatable {
    /// 1-based position in the strip (matches "Desktop N").
    let index: Int
    let title: String
    /// AX-coordinate frame (top-left origin).
    let frame: CGRect
}

/// Reads the Mission Control "Spaces Bar" thumbnails from the Dock's AX tree.
/// Only returns results while Mission Control is on screen.
enum SpacesBarReader {
    static func read() -> [SpaceThumbnail] {
        guard let list = spacesList() else { return [] }
        let buttons = AXReader.children(list).filter { AXReader.role($0) == "AXButton" }
        return buttons.enumerated().compactMap { index, button in
            guard let frame = AXReader.frame(button) else { return nil }
            return SpaceThumbnail(index: index + 1, title: AXReader.title(button), frame: frame)
        }
    }

    /// On-screen frame of the "Spaces Bar" group. When the bar is *collapsed*, the
    /// individual pill buttons report off-screen Y but this group frame stays on-screen
    /// (the top strip), so it's the anchor for positioning collapsed labels.
    static func barFrame() -> CGRect? {
        AXReader.dock().flatMap(spacesBar).flatMap(AXReader.frame)
    }

    private static func spacesBar(in dock: AXUIElement) -> AXUIElement? {
        AXReader.firstDescendant(of: dock, maxDepth: 24) {
            AXReader.role($0) == "AXGroup" && AXReader.title($0) == "Spaces Bar"
        }
    }

    private static func spacesList() -> AXUIElement? {
        guard let dock = AXReader.dock(), let bar = spacesBar(in: dock) else { return nil }
        return AXReader.children(bar).first { AXReader.role($0) == "AXList" }
    }
}
