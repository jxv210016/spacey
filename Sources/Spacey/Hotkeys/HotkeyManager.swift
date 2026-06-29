import AppKit
import Carbon.HIToolbox

/// Registers global hotkeys with the system via Carbon's `RegisterEventHotKey` and
/// dispatches them to a single `onAction` handler on the main actor.
///
/// Carbon hotkeys are the no-permission path: unlike a `CGEventTap`, they need neither
/// Input Monitoring nor Accessibility, and the WindowServer delivers the press as a
/// Carbon event on the main run loop. We install one shared event handler and keep a
/// map from our own incrementing hotkey id → action so `update(bindings:)` can rebuild
/// the whole set whenever the user edits a binding.
@MainActor
final class HotkeyManager {
    /// Invoked on the main actor when a registered hotkey fires.
    var onAction: ((HotkeyAction) -> Void)?

    private struct Registration {
        let ref: EventHotKeyRef
        let action: HotkeyAction
    }

    private var registrations: [UInt32: Registration] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextID: UInt32 = 1
    /// Four-char-code signature ('SPCY') tagging our hotkeys so we ignore others.
    private let signature: OSType = 0x5350_4359

    deinit {
        for registration in registrations.values {
            UnregisterEventHotKey(registration.ref)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    /// Replace all registered hotkeys with `bindings`. Safe to call repeatedly; the
    /// previous set is torn down first so re-binding never leaves a stale registration.
    func update(bindings: [HotkeyAction: KeyCombo]) {
        unregisterAll()
        installHandlerIfNeeded()
        for action in HotkeyAction.allCases {
            guard let combo = bindings[action] else { continue }
            register(action: action, combo: combo)
        }
    }

    /// Look up and fire the action for a hotkey id. Called from the C event handler,
    /// which Carbon delivers on the main thread.
    fileprivate func handle(id: UInt32) {
        guard let action = registrations[id]?.action else { return }
        onAction?(action)
    }

    // MARK: - Registration

    private func register(action: HotkeyAction, combo: KeyCombo) {
        let id = nextID
        nextID += 1
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(combo.keyCode),
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        // A non-zero status usually means the chord is already claimed system-wide; we
        // skip it rather than crash, and the binding simply won't fire until changed.
        guard status == noErr, let ref else { return }
        registrations[id] = Registration(ref: ref, action: action)
    }

    private func unregisterAll() {
        for registration in registrations.values {
            UnregisterEventHotKey(registration.ref)
        }
        registrations.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), hotKeyEventCallback, 1, &spec, context, &eventHandler)
    }
}

/// C event callback. Captures nothing, so it bridges to a `@convention(c)` pointer.
/// Pulls the firing hotkey id out of the Carbon event and forwards it to the manager
/// passed through `userData`.
private func hotKeyEventCallback(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    let id = hotKeyID.id
    // Carbon hotkey events arrive on the main thread, so we are already main-isolated.
    MainActor.assumeIsolated {
        manager.handle(id: id)
    }
    return noErr
}
