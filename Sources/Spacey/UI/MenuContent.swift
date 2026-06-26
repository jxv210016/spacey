import SwiftUI

/// The popover shown from the menu-bar item. Lists every Space and lets the user
/// name each one inline (label + icon + color). Switching/hotkeys arrive in Phase 3.
struct MenuContent: View {
    @ObservedObject var store: SpacesStore
    @ObservedObject var names: SpaceNamesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Divider()

            if !store.isAvailable {
                Label("SkyLight APIs unavailable on this macOS build.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            } else if store.allSpaces.isEmpty {
                Text("No spaces found.").foregroundStyle(.secondary)
            } else {
                spacesList
            }

            Divider()
            footer
        }
        .padding(12)
        .frame(width: 360)
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
                HStack(spacing: 4) {
                    Text("Display \(display.displayID.prefix(8))…")
                    if display.displayID == store.activeDisplayID {
                        Text("active").foregroundStyle(Color.accentColor)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            ForEach(display.spaces) { space in
                SpaceRow(space: space, names: names)
            }
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

/// A single editable Space row: current marker, color/icon pickers, and a name field.
private struct SpaceRow: View {
    let space: Space
    @ObservedObject var names: SpaceNamesStore

    /// Local edit buffer so typing does not write to disk / republish on every
    /// keystroke. Committed on submit and when focus leaves the field.
    @State private var draftLabel: String = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: space.isCurrent ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(space.isCurrent ? Color.accentColor : .secondary)
                .help(space.isCurrent ? "Current space" : "")

            colorPicker
            iconPicker

            TextField("Space \(space.indexOnDisplay)", text: $draftLabel)
                .textFieldStyle(.roundedBorder)
                .focused($isEditing)
                .onSubmit { commitLabel() }
                .onChange(of: isEditing) { _, editing in
                    if !editing { commitLabel() }
                }

            if name != nil {
                Button {
                    names.clear(space.identity)
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
                .help("Clear name")
            }
        }
        .onAppear { syncDraft() }
        // Keep the buffer in sync with external changes (e.g. Clear) while not typing.
        .onChange(of: name?.label) { _, _ in
            if !isEditing { syncDraft() }
        }
    }

    private var name: SpaceName? {
        names.name(for: space.identity)
    }

    private var resolvedColor: Color {
        name?.colorHex.flatMap(Color.init(hex:)) ?? .secondary
    }

    private func syncDraft() {
        draftLabel = name?.label ?? ""
    }

    private func commitLabel() {
        names.setLabel(draftLabel, for: space.identity)
    }

    private var colorPicker: some View {
        Menu {
            Button("None") { names.setColorHex(nil, for: space.identity) }
            ForEach(SpacePalette.colors, id: \.hex) { swatch in
                Button {
                    names.setColorHex(swatch.hex, for: space.identity)
                } label: {
                    Label(swatch.name, systemImage: "circle.fill")
                }
            }
        } label: {
            Image(systemName: "circle.fill").foregroundStyle(resolvedColor)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Color")
    }

    private var iconPicker: some View {
        Menu {
            Button("Default") { names.setSymbol(nil, for: space.identity) }
            ForEach(SpacePalette.symbols, id: \.self) { symbol in
                Button {
                    names.setSymbol(symbol, for: space.identity)
                } label: {
                    Label(symbol, systemImage: symbol)
                }
            }
        } label: {
            Image(systemName: SpaceDisplay.symbol(for: space, name: name))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Icon")
    }
}
