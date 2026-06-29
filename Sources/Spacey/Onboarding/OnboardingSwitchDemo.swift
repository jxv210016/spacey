import SwiftUI

/// "Switch in a snap" step: copy plus two synced mockups — a mini menu-bar capsule that
/// updates and a Quick Switcher palette whose highlight glides down the list — followed
/// by keycap hints for the default shortcuts. Animation pauses when Reduce Motion is on.
struct SwitchStepView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = 0

    private let spaces: [DemoSpace] = [
        DemoSpace(name: "Code", symbol: "terminal", color: .demoBlue),
        DemoSpace(name: "Design", symbol: "paintbrush", color: .demoPurple),
        DemoSpace(name: "Mail", symbol: "envelope", color: .demoGreen),
        DemoSpace(name: "Music", symbol: "music.note", color: .demoPink)
    ]

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 8)
            OnboardingHeader(
                symbol: "arrow.left.arrow.right",
                title: "Switch in a snap",
                subtitle: "Jump to any Space by name or number — your menu bar always shows where you are."
            )
            MenuBarCapsule(space: spaces[selection])
            paletteMock
            keycapLegend
            Spacer(minLength: 8)
        }
        .task(id: reduceMotion) { await cycle() }
    }

    // MARK: Quick Switcher mock

    private var paletteMock: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Search Spaces…")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            Divider()
            VStack(spacing: 2) {
                ForEach(Array(spaces.enumerated()), id: \.offset) { index, space in
                    paletteRow(space, index: index)
                }
            }
            .padding(6)
        }
        .frame(width: 280)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func paletteRow(_ space: DemoSpace, index: Int) -> some View {
        let isSelected = index == selection
        return HStack(spacing: 10) {
            DemoSpaceMark(color: space.color, symbol: space.symbol, diameter: 18)
            Text(space.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            Spacer(minLength: 8)
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.22) : .clear)
        )
    }

    // MARK: Shortcut hints

    private var keycapLegend: some View {
        VStack(spacing: 9) {
            legendRow(keys: ["⌥", "Space"], text: "Open the Quick Switcher")
            legendRow(keys: ["⌃", "⌥", "1–9"], text: "Jump straight to a desktop")
        }
    }

    private func legendRow(keys: [String], text: String) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { OnboardingKeycap(label: $0) }
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(width: 280)
    }

    private func cycle() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1.7))
            withAnimation(.easeInOut(duration: 0.55)) {
                selection = (selection + 1) % spaces.count
            }
        }
    }
}
