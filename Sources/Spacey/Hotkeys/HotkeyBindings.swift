import Combine
import Foundation

/// Persists the user's hotkey chords per `HotkeyAction`, backed by `UserDefaults` +
/// JSON to stay dependency-free and testable against an ephemeral suite (the same
/// pattern as `AppearanceSettings` / `SpaceNamesStore`).
///
/// On first launch (no stored data) it seeds `HotkeyAction.defaultBindings`. Once the
/// user has changed anything we persist the exact dictionary, so an action the user
/// *cleared* stays cleared (absent from the map) rather than springing back to a default.
@MainActor
final class HotkeyBindings: ObservableObject {
    @Published private(set) var bindings: [HotkeyAction: KeyCombo]

    private static let storageKey = "com.getspacey.hotkeys.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bindings = Self.load(from: defaults) ?? HotkeyAction.defaultBindings
    }

    // MARK: - Reads

    func combo(for action: HotkeyAction) -> KeyCombo? {
        bindings[action]
    }

    // MARK: - Mutations

    /// Assign (or, with `nil`, clear) the chord for an action.
    func set(_ combo: KeyCombo?, for action: HotkeyAction) {
        if let combo {
            bindings[action] = combo
        } else {
            bindings.removeValue(forKey: action)
        }
        persist()
    }

    func clear(_ action: HotkeyAction) {
        set(nil, for: action)
    }

    // MARK: - Persistence

    private func persist() {
        // Encode with the raw string keys so the JSON is stable and human-inspectable.
        let raw = Dictionary(uniqueKeysWithValues: bindings.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(raw) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private static func load(from defaults: UserDefaults) -> [HotkeyAction: KeyCombo]? {
        guard let data = defaults.data(forKey: storageKey),
              let raw = try? JSONDecoder().decode([String: KeyCombo].self, from: data)
        else { return nil }

        var result: [HotkeyAction: KeyCombo] = [:]
        for (key, combo) in raw {
            if let action = HotkeyAction(rawValue: key) { result[action] = combo }
        }
        return result
    }
}
