import SwiftUI

/// First-run onboarding: a friendly, centered flow that welcomes the user, explains
/// what Spacey does, walks through granting Accessibility (with live status), and
/// finishes by marking onboarding complete.
struct OnboardingView: View {
    @ObservedObject var state: OnboardingState
    @ObservedObject var accessibility: AccessibilityMonitor
    let onFinish: () -> Void

    private enum Step {
        case welcome
        case permission
    }

    @State private var step: Step = .welcome

    private var hasAccessibility: Bool {
        accessibility.isTrusted
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 36)
            footer
        }
        .frame(width: 460, height: 560)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcomeStep
        case .permission:
            permissionStep
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            VStack(spacing: 6) {
                Text("Welcome to \(AppInfo.name)")
                    .font(.largeTitle.weight(.bold))
                Text(AppInfo.tagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 16) {
                feature(
                    "textformat",
                    "Name your desktops",
                    "Give each Space a label, icon, and color."
                )
                feature(
                    "arrow.left.arrow.right",
                    "Switch by name",
                    "Jump to any Space from the menu-bar list."
                )
                feature(
                    "rectangle.3.group",
                    "Names in Mission Control",
                    "See your custom names right inside Mission Control."
                )
            }
            .padding(.top, 6)
            Spacer(minLength: 12)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Permission

    private var permissionStep: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)
            Image(systemName: hasAccessibility ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 52))
                .foregroundStyle(hasAccessibility ? Color.green : Color.orange)
            VStack(spacing: 6) {
                Text("Enable Accessibility")
                    .font(.largeTitle.weight(.bold))
                Text(
                    "Spacey needs Accessibility access to read Mission Control and "
                        + "switch Spaces for you. It never sees your content."
                )
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            statusRow
            Spacer(minLength: 12)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(hasAccessibility ? Color.green : Color.orange)
            Text(hasAccessibility ? "Accessibility granted" : "Accessibility not yet granted")
                .font(.callout.weight(.medium))
            Spacer()
            if !hasAccessibility {
                Button("Grant Accessibility…") { accessibility.requestAccess() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
        .padding(.top, 8)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            pageDots
            Spacer()
            footerButtons
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(.bar)
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            dot(active: step == .welcome)
            dot(active: step == .permission)
        }
    }

    private func dot(active: Bool) -> some View {
        Circle()
            .fill(active ? Color.primary.opacity(0.7) : Color.secondary.opacity(0.3))
            .frame(width: 7, height: 7)
    }

    @ViewBuilder
    private var footerButtons: some View {
        switch step {
        case .welcome:
            Button("Continue") { step = .permission }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
        case .permission:
            Button("Back") { step = .welcome }
                .controlSize(.large)
            Button("Get Started") { finish() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func finish() {
        state.complete()
        onFinish()
    }
}
