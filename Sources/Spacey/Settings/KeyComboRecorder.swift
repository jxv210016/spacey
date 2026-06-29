import AppKit
import Carbon.HIToolbox
import SwiftUI

/// A self-contained key-chord recorder. Tapping it starts listening; the next valid
/// chord (a real key plus at least one of ⌃⌥⌘) is captured via a local `NSEvent`
/// monitor and handed back through `onRecord`. Esc cancels, Delete clears.
///
/// Built by hand (no `KeyboardShortcuts` dependency) so it matches the project's
/// zero-dependency rule while still feeling like the system recorder.
struct KeyComboRecorder: View {
    /// The currently bound chord, if any.
    let combo: KeyCombo?
    let onRecord: (KeyCombo) -> Void
    let onClear: () -> Void

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggleRecording) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: isRecording ? .default : .rounded))
                    .foregroundStyle(isRecording ? Color.accentColor : .primary)
                    .frame(minWidth: 104)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .help(isRecording ? "Press a shortcut, or Esc to cancel" : "Click to record a shortcut")

            if combo != nil, !isRecording {
                Button(action: clear) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear shortcut")
            }
        }
        .onDisappear(perform: stopRecording)
    }

    private var label: String {
        if isRecording { return "Press shortcut…" }
        return combo?.displayString ?? "Record Shortcut"
    }

    // MARK: - Recording lifecycle

    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event)
            return nil // consume everything while recording
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private func clear() {
        onClear()
    }

    private func handle(_ event: NSEvent) {
        // Esc cancels without changing the binding.
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }
        // Delete clears the binding.
        if event.keyCode == UInt16(kVK_Delete) {
            onClear()
            stopRecording()
            return
        }

        let candidate = KeyCombo(keyCode: event.keyCode, modifiers: event.modifierFlags)
        // Require a "real" modifier so the chord won't fire during normal typing.
        guard candidate.hasCommandModifier else {
            NSSound.beep()
            return
        }
        onRecord(candidate)
        stopRecording()
    }
}
