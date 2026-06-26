import SwiftUI

/// The popover shown from the menu-bar item. Phase 0: a read-only live view of the
/// current Spaces layout, proving the SkyLight read path. Naming, switching, and
/// hotkeys arrive in later phases.
struct MenuContent: View {
    @ObservedObject var store: SpacesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Divider()

            if !store.isAvailable {
                Label("SkyLight APIs unavailable on this macOS build.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            } else if store.allSpaces.isEmpty {
                Text("No spaces found.")
                    .foregroundStyle(.secondary)
            } else {
                spacesList
            }

            Divider()

            footer
        }
        .padding(12)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Image(systemName: "rectangle.3.group.fill")
            Text("Spacey").font(.headline)
            Spacer()
            Text("v0.1.0").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var spacesList: some View {
        ForEach(Array(store.displays.enumerated()), id: \.element.displayID) { _, display in
            if store.displays.count > 1 {
                Text("Display \(display.displayID.prefix(8))…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(display.spaces) { space in
                spaceRow(space)
            }
        }
    }

    private func spaceRow(_ space: Space) -> some View {
        HStack(spacing: 8) {
            Image(systemName: space.isCurrent ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(space.isCurrent ? Color.accentColor : .secondary)
            Text("Space \(space.indexOnDisplay)")
            if !space.isUserSpace {
                Text("fullscreen/type \(space.type)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(space.uuid.prefix(8) + "…")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    private var footer: some View {
        HStack {
            Button("Refresh") { store.refresh() }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
