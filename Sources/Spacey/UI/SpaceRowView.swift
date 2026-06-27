import SwiftUI

/// A single Space row: a color dot (click to change color), the name, current-Space
/// emphasis, and hover-revealed controls. Clicking the row switches to that Space;
/// renaming is a deliberate action (the pencil).
struct SpaceRowView: View {
    let space: Space
    @ObservedObject var names: SpaceNamesStore
    let onActivate: () -> Void

    @State private var draftLabel = ""
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var showColorPicker = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            colorDot
            nameView
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { if !isEditing { onActivate() } }
            trailing
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(rowBackground)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .help(space.isCurrent ? "Current Space" : "Switch to this Space")
        .onAppear { syncDraft() }
        .onChange(of: name?.label) { _, _ in if !isEditing { syncDraft() } }
    }

    // MARK: Pieces

    @ViewBuilder
    private var nameView: some View {
        if isEditing {
            TextField(defaultName, text: $draftLabel)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($fieldFocused)
                .onSubmit { endEditing() }
                .onChange(of: fieldFocused) { _, focused in if !focused { endEditing() } }
        } else {
            Text(displayName)
                .font(.system(size: 13, weight: space.isCurrent ? .semibold : .regular))
                .foregroundStyle(name?.trimmedLabel == nil ? .secondary : .primary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isHovering || isEditing {
            controls.transition(.opacity)
        }
    }

    private var controls: some View {
        HStack(spacing: 3) {
            iconMenu
            iconButton("pencil", help: "Rename") { startEditing() }
            if name != nil {
                iconButton("xmark.circle.fill", help: "Clear") { names.clear(space.identity) }
            }
        }
        .foregroundStyle(.secondary)
    }

    private var colorDot: some View {
        Button {
            showColorPicker = true
        } label: {
            ZStack {
                Circle().fill(Color.primary.opacity(isHovering ? 0.12 : 0))
                SpaceMark(color: color, symbol: name?.symbol, isCurrent: space.isCurrent)
            }
            .frame(width: 24, height: 24)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Change color")
        .popover(isPresented: $showColorPicker, arrowEdge: .bottom) {
            ColorSwatchPicker(current: name?.colorHex) { hex in
                names.setColorHex(hex, for: space.identity)
                showColorPicker = false
            }
        }
    }

    private var iconMenu: some View {
        Menu {
            Button("Default icon") { names.setSymbol(nil, for: space.identity) }
            ForEach(SpacePalette.symbols, id: \.self) { symbol in
                Button {
                    names.setSymbol(symbol, for: space.identity)
                } label: {
                    Label(symbol, systemImage: symbol)
                }
            }
        } label: {
            Image(systemName: SpaceDisplay.symbol(for: space, name: name))
                .font(.system(size: 12))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Icon")
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private var rowBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        if isHovering {
            shape.fill(Color.primary.opacity(0.07))
        } else if space.isCurrent {
            shape.fill(Color.accentColor.opacity(0.10))
        } else {
            shape.fill(.clear)
        }
    }

    // MARK: Data

    private var name: SpaceName? {
        names.name(for: space.identity)
    }

    private var color: Color? {
        name?.colorHex.flatMap(Color.init(hex:))
    }

    private var defaultName: String {
        "Desktop \(space.indexOnDisplay)"
    }

    private var displayName: String {
        name?.trimmedLabel ?? defaultName
    }

    private func syncDraft() {
        draftLabel = name?.label ?? ""
    }

    private func startEditing() {
        syncDraft()
        isEditing = true
        fieldFocused = true
    }

    private func endEditing() {
        names.setLabel(draftLabel, for: space.identity)
        isEditing = false
    }
}

/// The leading mark: a color dot. If the Space has an icon, it sits inside the dot;
/// with no color it's a subtle outlined dot. The current Space gets an accent ring.
private struct SpaceMark: View {
    let color: Color?
    let symbol: String?
    var isCurrent = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color ?? Color.secondary.opacity(0.18))
            if color == nil {
                Circle().strokeBorder(Color.secondary.opacity(0.45), lineWidth: 1)
            }
            if let symbol, !symbol.isEmpty {
                Image(systemName: symbol)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color == nil ? Color.secondary : .white)
            }
        }
        .frame(width: 14, height: 14)
        .overlay {
            if isCurrent {
                Circle().strokeBorder(Color.accentColor, lineWidth: 1.5).padding(-3)
            }
        }
    }
}

/// A compact grid of color swatches shown in a popover from the color dot.
private struct ColorSwatchPicker: View {
    let current: String?
    let onSelect: (String?) -> Void

    private let columns = Array(repeating: GridItem(.fixed(24), spacing: 10), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            LazyVGrid(columns: columns, spacing: 10) {
                swatch(hex: nil)
                ForEach(SpacePalette.colors, id: \.hex) { swatch(hex: $0.hex) }
            }
        }
        .padding(14)
    }

    private func swatch(hex: String?) -> some View {
        Button { onSelect(hex) } label: {
            ZStack {
                Circle().fill(hex.flatMap(Color.init(hex:)) ?? Color.secondary.opacity(0.15))
                if hex == nil {
                    Image(systemName: "slash.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                if hex == current {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(hex == nil ? Color.secondary : .white)
                }
            }
            .frame(width: 22, height: 22)
            .overlay(Circle().strokeBorder(.primary.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help(hex == nil ? "No color" : "")
    }
}
