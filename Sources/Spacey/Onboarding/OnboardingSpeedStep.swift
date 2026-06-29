import AppKit
import SwiftUI

/// Best-effort deep links into System Settings. macOS doesn't expose reliable anchors to
/// the exact sub-panes for these, so we open the closest top-level pane we can and spell
/// out the remaining path in the UI. URLs are guarded (never force-unwrapped).
enum OnboardingLinks {
    /// Keyboard settings pane (Keyboard Shortcuts ▸ Mission Control lives here).
    static let keyboardSettings = "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"

    static func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }

    static func openKeyboardSettings() { open(keyboardSettings) }
}

/// Optional speed-up: switching already works out of the box, but turning on macOS's
/// "Switch to Desktop" shortcuts lets Spacey jump in a single motion. Entirely optional —
/// framed that way so onboarding never feels like a chore.
struct SpeedStepView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)
            OnboardingHeader(
                symbol: "bolt.fill",
                title: "Optional: instant jumps",
                subtitle: "Switching already works — this just makes a far jump one quick "
                    + "motion instead of stepping across. Skip it if you like."
            )
            SetupCard(
                symbol: "command.square",
                title: "Turn on “Switch to Desktop 1–9”",
                detail: "In the panel that opens, pick Mission Control and check "
                    + "“Switch to Desktop 1” through 9. Spacey then jumps straight there; "
                    + "without it, it steps left/right (still works).",
                path: "Keyboard ▸ Keyboard Shortcuts… ▸ Mission Control",
                buttonTitle: "Open Keyboard Settings…",
                action: OnboardingLinks.openKeyboardSettings
            )
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
