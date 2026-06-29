import AppKit
import Carbon.HIToolbox
import SwiftUI

/// A borderless `NSPanel` that is allowed to become the key window so it can receive
/// keyboard focus. Plain borderless windows refuse key status, which would leave the
/// palette unable to capture typing — overriding these two properties fixes that.
final class QuickSwitcherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Owns the Quick Switcher palette: a centered, floating panel presented on demand.
///
/// Like `SettingsPresenter`/`OnboardingPresenter`, the palette is a manually managed
/// window because the SwiftUI scene machinery no-ops for an `.accessory` app. To get
/// keyboard focus we briefly become a regular app (`AppActivation.becomeRegular`); the
/// existing window-close observer reverts to `.accessory` once the panel closes.
///
/// All key input is captured by a local `NSEvent` monitor while the panel is open and
/// routed into `QuickSwitcherModel`, so the SwiftUI content can stay declarative.
@MainActor
final class QuickSwitcherPresenter: NSObject, NSWindowDelegate {
    private let store: SpacesStore
    private let names: SpaceNamesStore
    private let model = QuickSwitcherModel()

    private var panel: NSPanel?
    private var keyMonitor: Any?

    init(store: SpacesStore, names: SpaceNamesStore) {
        self.store = store
        self.names = names
    }

    /// Toggle the palette: dismiss if open, otherwise present it.
    func toggle() {
        if panel == nil { show() } else { dismiss() }
    }

    func show() {
        let entries = QuickSwitcherEntry.entries(store: store, names: names)
        guard !entries.isEmpty else { NSSound.beep(); return }
        model.reset(entries: entries)

        AppActivation.becomeRegular()

        let panel = makePanel()
        self.panel = panel
        installKeyMonitor()
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        removeKeyMonitor()
        panel?.close()
        panel = nil
    }

    // MARK: - Window

    private func makePanel() -> NSPanel {
        let content = QuickSwitcherView(model: model) { [weak self] entry in self?.activate(entry) }
        let panel = QuickSwitcherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.delegate = self
        let host = NSHostingView(rootView: content)
        host.frame = panel.contentLayoutRect
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        // Size the panel to the SwiftUI content's natural height.
        panel.setContentSize(host.fittingSize)
        return panel
    }

    /// Dismiss when the palette loses key status (e.g. the user clicks another app).
    func windowDidResignKey(_: Notification) {
        dismiss()
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handle(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// Returns `true` if the event was consumed by the palette.
    private func handle(_ event: NSEvent) -> Bool {
        switch Int(event.keyCode) {
        case kVK_Escape:
            dismiss()
            return true
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if let entry = model.selectedEntry { activate(entry) }
            return true
        case kVK_UpArrow:
            model.moveSelection(by: -1)
            return true
        case kVK_DownArrow:
            model.moveSelection(by: 1)
            return true
        case kVK_Delete:
            model.deleteBackward()
            return true
        default:
            return handleCharacter(event)
        }
    }

    private func handleCharacter(_ event: NSEvent) -> Bool {
        // Ignore chords with command/control/option — they aren't query text and we
        // don't want them silently swallowed.
        guard event.modifierFlags.isDisjoint(with: [.command, .control, .option]) else { return false }
        guard let characters = event.charactersIgnoringModifiers, let scalar = characters.unicodeScalars.first else {
            return false
        }

        // 1–9 are numeric quick-jump to the Nth visible result.
        if let digit = Int(characters), (1 ... 9).contains(digit) {
            if let entry = model.entry(forNumber: digit) { activate(entry) }
            return true
        }

        // Any other printable character extends the filter text.
        if scalar.value >= 0x20, scalar.value != 0x7F {
            model.appendToQuery(characters)
            return true
        }
        return false
    }

    // MARK: - Navigation

    /// Switch to `entry` by stepping from the current Space on its display, mirroring
    /// `MenuContent.activate(_:)`. Indices are re-resolved from the live store so a
    /// stale snapshot can't send us to the wrong desktop.
    private func activate(_ entry: QuickSwitcherEntry) {
        dismiss()
        guard !entry.isCurrent,
              let display = store.displays.first(where: { $0.displayID == entry.displayID }),
              let current = display.spaces.first(where: { $0.isCurrent })
        else { return }
        SpaceSwitcher.navigate(fromIndex: current.indexOnDisplay, toIndex: entry.indexOnDisplay)
    }
}
