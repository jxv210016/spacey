import SwiftUI

/// The Quick Switcher's SwiftUI content: a search field-styled query line above a
/// scrolling list of matching Spaces. It is display-only — all keyboard input is
/// captured by the presenter's `NSEvent` monitor and pushed into the model — so this
/// view just reflects state and forwards row clicks.
struct QuickSwitcherView: View {
    @ObservedObject var model: QuickSwitcherModel
    /// Switch to the clicked/selected entry.
    let onSelect: (QuickSwitcherEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            queryField
            Divider()
            results
        }
        .frame(width: 460)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: Query line

    private var queryField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            ZStack(alignment: .leading) {
                if model.query.isEmpty {
                    Text("Search Spaces…")
                        .foregroundStyle(.secondary)
                }
                Text(model.query)
            }
            .font(.system(size: 16))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: Results

    @ViewBuilder
    private var results: some View {
        let entries = model.results
        if entries.isEmpty {
            Text("No matching Spaces")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            row(entry, index: index)
                                .id(entry.id)
                        }
                    }
                    .padding(8)
                }
                .frame(height: listHeight(count: entries.count))
                .onChange(of: model.selection) { _, _ in
                    guard let entry = model.selectedEntry else { return }
                    withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(entry.id, anchor: .center) }
                }
            }
        }
    }

    private func listHeight(count: Int) -> CGFloat {
        let rowHeight: CGFloat = 40
        return min(CGFloat(count) * rowHeight + 16, 360)
    }

    private func row(_ entry: QuickSwitcherEntry, index: Int) -> some View {
        let isSelected = index == model.selection
        return HStack(spacing: 11) {
            mark(for: entry)
            Text(entry.title)
                .font(.system(size: 14, weight: entry.isCurrent ? .semibold : .regular))
                .lineLimit(1)
            Spacer(minLength: 8)
            if entry.isCurrent {
                Text("current")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            // Numeric quick-jump hint for the first nine results.
            if index < 9 {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(rowBackground(isSelected: isSelected))
        .contentShape(Rectangle())
        .onTapGesture { onSelect(entry) }
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        if isSelected {
            shape.fill(Color.accentColor.opacity(0.22))
        } else {
            shape.fill(.clear)
        }
    }

    private func mark(for entry: QuickSwitcherEntry) -> some View {
        let color = entry.colorHex.flatMap(Color.init(hex:))
        return ZStack {
            Circle().fill(color ?? Color.secondary.opacity(0.18))
            if color == nil {
                Circle().strokeBorder(Color.secondary.opacity(0.45), lineWidth: 1)
            }
            Image(systemName: entry.symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color == nil ? Color.secondary : .white)
        }
        .frame(width: 22, height: 22)
    }
}
