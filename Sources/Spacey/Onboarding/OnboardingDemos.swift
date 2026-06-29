import SwiftUI

/// Self-contained sample data for the onboarding demo mockups. Deliberately independent
/// of the real `Space`/`SpaceName` types so the demos never touch live state — they just
/// need a label, an SF Symbol, and a color that *resembles* the real palette.
struct DemoSpace: Hashable {
    let name: String
    let symbol: String
    let color: Color
}

extension Color {
    /// A few swatches mirroring `SpacePalette` so the demos look like the real UI,
    /// declared as plain `Color`s to stay self-contained (no hex parsing / optionals).
    static let demoBlue = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let demoPurple = Color(red: 0.75, green: 0.35, blue: 0.95)
    static let demoGreen = Color(red: 0.20, green: 0.84, blue: 0.29)
    static let demoPink = Color(red: 1.0, green: 0.22, blue: 0.37)
}

/// Shared section header for the demo steps: a tinted glyph, a bold title, and a
/// secondary subtitle — matching the welcome/permission steps' look exactly.
struct OnboardingHeader: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            VStack(spacing: 6) {
                Text(title).font(.largeTitle.weight(.bold))
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// A filled color dot with a white SF Symbol inside — a self-contained echo of the real
/// `SpaceMark`. The current Space gets an accent ring.
struct DemoSpaceMark: View {
    let color: Color
    let symbol: String
    var isCurrent = false
    var diameter: CGFloat = 16

    var body: some View {
        Circle()
            .fill(color)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: diameter * 0.55, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: diameter, height: diameter)
            .overlay {
                if isCurrent {
                    Circle().strokeBorder(Color.accentColor, lineWidth: 1.5).padding(-3)
                }
            }
    }
}

/// A small keycap: a rounded rect holding a glyph or short label (e.g. ⌥, Space, 1–9).
struct OnboardingKeycap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .frame(minWidth: 22, minHeight: 22)
            .padding(.horizontal, 5)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 0.5)
            )
    }
}

/// A compact capsule resembling the menu-bar item (icon + current Space name).
struct MenuBarCapsule: View {
    let space: DemoSpace

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: space.symbol)
            Text(space.name).contentTransition(.opacity)
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quaternary.opacity(0.6), in: Capsule())
        .overlay(Capsule().strokeBorder(.primary.opacity(0.10), lineWidth: 0.5))
    }
}

/// "Name your desktops" step: copy plus an animated Space-row mockup that gently cycles
/// through a few example names, icons, and colors. Static when Reduce Motion is on.
struct NamingStepView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let examples: [DemoSpace] = [
        DemoSpace(name: "Code", symbol: "terminal", color: .demoBlue),
        DemoSpace(name: "Design", symbol: "paintbrush", color: .demoPurple),
        DemoSpace(name: "Music", symbol: "music.note", color: .demoPink)
    ]

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)
            OnboardingHeader(
                symbol: "textformat",
                title: "Name your desktops",
                subtitle: "Give each Space a label, icon, and color — so you always know where you are."
            )
            rowMockup
            Spacer(minLength: 12)
        }
        .task(id: reduceMotion) { await cycle() }
    }

    private var rowMockup: some View {
        let example = examples[index]
        return HStack(spacing: 11) {
            DemoSpaceMark(color: example.color, symbol: example.symbol, isCurrent: true)
            Text(example.name)
                .font(.system(size: 14, weight: .semibold))
                .contentTransition(.opacity)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(width: 220)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func cycle() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.0))
            withAnimation(.easeInOut(duration: 0.7)) {
                index = (index + 1) % examples.count
            }
        }
    }
}
