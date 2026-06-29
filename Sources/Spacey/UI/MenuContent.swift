import SwiftUI

/// The popover shown from the menu-bar item: a clean list of Spaces with inline
/// naming (label + icon + color), the current Space emphasized, and a Mission
/// Control toggle. Editing controls are revealed on hover to keep it uncluttered.
struct MenuContent: View {
    @ObservedObject var store: SpacesStore
    @ObservedObject var names: SpaceNamesStore
    @ObservedObject var labeler: MissionControlLabeler
    @ObservedObject var accessibility: AccessibilityMonitor
    @ObservedObject var appearance: AppearanceSettings
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            if store.isAvailable {
                AddDesktopButton()
            }
            Divider()
            footer
        }
        .frame(width: 300)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "square.grid.2x2.fill")
                .foregroundStyle(.tint)
            Text("Spacey").font(.headline)
            Spacer()
            if let current = store.currentSpace {
                Text(SpaceDisplay.title(for: current, name: names.name(for: current.identity)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if !store.isAvailable {
            emptyState(
                icon: "exclamationmark.triangle",
                title: "Spaces unavailable",
                message: "This macOS build doesn’t expose the Spaces API Spacey needs."
            )
        } else if store.allSpaces.isEmpty {
            emptyState(
                icon: "rectangle.on.rectangle.slash",
                title: "No Spaces found",
                message: "Add desktops in Mission Control and they’ll appear here."
            )
        } else {
            spacesList
        }
    }

    private var spacesList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(store.displays.enumerated()), id: \.element.displayID) { _, display in
                    if store.displays.count > 1 {
                        displayHeader(display)
                    }
                    ForEach(display.spaces) { space in
                        SpaceRowView(space: space, names: names, appearance: appearance, onActivate: { activate(space) })
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(height: listHeight)
    }

    /// Natural height of the list (so the popover sizes correctly), capped so long
    /// lists scroll instead of growing without bound.
    private var listHeight: CGFloat {
        let rowHeight: CGFloat = 35
        let headerHeight: CGFloat = store.displays.count > 1 ? 24 : 0
        let raw = 12
            + CGFloat(store.allSpaces.count) * rowHeight
            + CGFloat(store.displays.count) * headerHeight
        return min(raw, 360)
    }

    private func displayHeader(_ display: DisplaySpaces) -> some View {
        HStack(spacing: 5) {
            Text("Display")
            if display.displayID == store.activeDisplayID {
                Text("· active").foregroundStyle(.tint)
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text(title).font(.callout.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $labeler.isEnabled) {
                Label("Names in Mission Control", systemImage: "rectangle.3.group")
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)

            if labeler.isEnabled, !accessibility.isTrusted {
                permissionNotice
            }

            Divider()

            HStack(spacing: 12) {
                Text("Spacey")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Settings…") { onOpenSettings() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut(",")
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut("q")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private var permissionNotice: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("Accessibility permission needed")
                    .font(.caption.weight(.medium))
                Text("So Spacey can read Mission Control.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button("Open Settings…") { accessibility.requestAccess() }
                    .buttonStyle(.link)
                    .font(.caption)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 9)
    }

    /// Switch to `space` by stepping from the current Space on its display.
    private func activate(_ space: Space) {
        guard !space.isCurrent,
              let display = store.displays.first(where: { $0.displayID == space.displayID }),
              let current = display.spaces.first(where: { $0.isCurrent })
        else { return }
        SpaceSwitcher.move(
            toIndex: space.indexOnDisplay,
            fromIndex: current.indexOnDisplay,
            displayCount: store.displays.count
        )
    }
}

/// "Add Desktop" styled as a continuation of the Spaces list: the plus glyph sits in the
/// same column as the rows' color dots and the whole row picks up the same hover
/// highlight, so it reads as one more entry rather than a detached button.
private struct AddDesktopButton: View {
    @State private var isHovering = false

    var body: some View {
        Button(action: SpaceActions.addDesktop) {
            HStack(spacing: 10) {
                mark
                Text("Add Desktop")
                    .font(.system(size: 13))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(background)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .help("Open Mission Control and add a desktop")
    }

    /// Mirrors the rows' no-color dot (an outlined circle) with a plus inside.
    private var mark: some View {
        Image(systemName: "plus")
            .font(.system(size: 9, weight: .bold))
            .frame(width: 14, height: 14)
            .background(Circle().strokeBorder(Color.secondary.opacity(0.45), lineWidth: 1))
            .frame(width: 24, height: 24)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        if isHovering {
            shape.fill(Color.primary.opacity(0.07))
        } else {
            shape.fill(.clear)
        }
    }
}
