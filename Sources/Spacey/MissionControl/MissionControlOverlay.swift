import AppKit
import SwiftUI

/// A name label to paint over one Space thumbnail.
struct OverlayLabel: Identifiable, Equatable {
    let id: Int
    let text: String
    let colorHex: String?
    let symbol: String?
    /// AX-coordinate frame of the thumbnail (top-left origin).
    let frame: CGRect
}

/// Pure mapping from Spaces-Bar thumbnails + our named Spaces to overlay labels.
/// Thumbnails are positional ("Desktop N"), so index N maps to the Nth Space on the
/// display, in order. Only Spaces with a non-empty custom label produce a label.
enum OverlayMapping {
    static func labels(
        thumbnails: [SpaceThumbnail],
        spaces: [Space],
        name: (String) -> SpaceName?
    ) -> [OverlayLabel] {
        thumbnails.compactMap { thumbnail in
            guard thumbnail.index >= 1, thumbnail.index <= spaces.count else { return nil }
            let space = spaces[thumbnail.index - 1]
            guard let record = name(space.identity), let text = record.trimmedLabel else { return nil }
            return OverlayLabel(
                id: thumbnail.index,
                text: text,
                colorHex: record.colorHex,
                symbol: record.symbol,
                frame: thumbnail.frame
            )
        }
    }
}

/// SwiftUI content drawn across the whole screen. Because the host window covers the
/// screen exactly, SwiftUI's top-left coordinate space lines up with AX coordinates,
/// so thumbnail frames are used directly.
private struct OverlayContent: View {
    let labels: [OverlayLabel]
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(labels) { label in
                chip(label)
                    // Sit just under the thumbnail's bottom edge, like a name tag.
                    .position(x: label.frame.midX, y: label.frame.maxY + 12)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func chip(_ label: OverlayLabel) -> some View {
        HStack(spacing: 5) {
            if let symbol = label.symbol, !symbol.isEmpty {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            }
            Text(label.text)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(accent(label).gradient))
        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.35), radius: 5, y: 1)
        .fixedSize()
    }

    private func accent(_ label: OverlayLabel) -> Color {
        label.colorHex.flatMap(Color.init(hex:)) ?? .accentColor
    }
}

/// Manages the transparent, click-through overlay window that floats above Mission
/// Control. Uses a `.screenSaver`-level non-activating panel, presented only while MC
/// is open (event-timed presentation — a persistent top-level window gets hidden by
/// MC, so we order it in fresh each time).
@MainActor
final class MissionControlOverlayWindow {
    private var panel: NSPanel?

    func show(labels: [OverlayLabel], on screen: NSScreen) {
        let frame = screen.frame
        let content = OverlayContent(labels: labels, size: frame.size)
        let panel = panel ?? makePanel(frame: frame)
        panel.setFrame(frame, display: false)

        if let host = panel.contentView as? NSHostingView<OverlayContent> {
            host.rootView = content
        } else {
            panel.contentView = NSHostingView(rootView: content)
        }
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel(frame: NSRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // NSWindow.Level.screenSaver is only 101 — too low to clear Mission Control.
        // Use the real CG shielding level (~1000+), which sits above the MC overview.
        panel.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        return panel
    }
}
