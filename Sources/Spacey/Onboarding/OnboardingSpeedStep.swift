import AppKit
import SwiftUI

/// Best-effort deep links into System Settings. macOS doesn't expose reliable anchors to
/// the exact sub-panes for these, so we open the closest top-level pane we can and spell
/// out the remaining path in the UI. URLs are guarded (never force-unwrapped).
enum OnboardingLinks {
    /// Keyboard settings pane (Keyboard Shortcuts ▸ Mission Control lives here).
    static let keyboardSettings = "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
    /// Accessibility settings pane (Display ▸ Reduce Motion lives here).
    static let accessibilitySettings = "x-apple.systempreferences:com.apple.Accessibility-Settings.extension"

    static func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }

    static func openKeyboardSettings() { open(keyboardSettings) }

    static func openAccessibilitySettings() { open(accessibilitySettings) }
}

/// "Make it instant" step: two optional macOS settings that make switching feel
/// immediate. Spacey auto-detects and uses them; this is guidance, not a requirement.
struct SpeedStepView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)
            OnboardingHeader(
                symbol: "bolt.fill",
                title: "Make it instant",
                subtitle: "Two optional macOS settings make every jump feel immediate. "
                    + "Both are off by default — Spacey uses them automatically once they're on."
            )
            VStack(spacing: 12) {
                SetupCard(
                    symbol: "command.square",
                    title: "“Switch to Desktop 1–9” shortcuts",
                    detail: "Enable these for the fastest direct jumps. "
                        + "Without them, Spacey steps left/right to reach a desktop.",
                    path: "System Settings ▸ Keyboard ▸ Keyboard Shortcuts ▸ Mission Control",
                    buttonTitle: "Open Keyboard Settings…",
                    action: OnboardingLinks.openKeyboardSettings
                )
                SetupCard(
                    symbol: "figure.walk.motion",
                    title: "Reduce Motion",
                    detail: "Turns the macOS Space-switch slide into a near-instant crossfade.",
                    path: "System Settings ▸ Accessibility ▸ Display",
                    buttonTitle: "Open Accessibility…",
                    action: OnboardingLinks.openAccessibilitySettings
                )
            }
            Spacer(minLength: 12)
        }
    }
}

/// One optional-setting card: glyph + title + detail, the manual settings path, and a
/// best-effort deep-link button.
private struct SetupCard: View {
    let symbol: String
    let title: String
    let detail: String
    let path: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            HStack {
                Spacer(minLength: 0)
                Button(buttonTitle, action: action).controlSize(.small)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}
