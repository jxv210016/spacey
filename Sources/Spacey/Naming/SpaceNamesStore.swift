import Combine
import Foundation

/// Persists custom Space names, keyed by `Space.identity` (stable across reboots and
/// macOS auto-reordering). Backed by `UserDefaults` + JSON so it has no external
/// dependency and can be tested against an ephemeral suite.
@MainActor
final class SpaceNamesStore: ObservableObject {
    @Published private(set) var names: [String: SpaceName]

    private let defaults: UserDefaults
    private let storageKey = "com.getspacey.spaceNames.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        names = Self.load(from: defaults, key: storageKey)
    }

    // MARK: - Reads

    func name(for identity: String) -> SpaceName? {
        names[identity]
    }

    // MARK: - Mutations

    /// Set or clear the full name record for an identity. Empty records are removed.
    func setName(_ name: SpaceName?, for identity: String) {
        if let name, !name.isEmpty {
            names[identity] = name
        } else {
            names.removeValue(forKey: identity)
        }
        persist()
    }

    func setLabel(_ label: String, for identity: String) {
        update(identity) { $0.label = label }
    }

    func setSymbol(_ symbol: String?, for identity: String) {
        update(identity) { $0.symbol = symbol }
    }

    func setColorHex(_ colorHex: String?, for identity: String) {
        update(identity) { $0.colorHex = colorHex }
    }

    func clear(_ identity: String) {
        setName(nil, for: identity)
    }

    private func update(_ identity: String, _ mutate: (inout SpaceName) -> Void) {
        var record = names[identity] ?? SpaceName()
        mutate(&record)
        setName(record, for: identity)
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(names) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [String: SpaceName] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: SpaceName].self, from: data)
        else { return [:] }
        return decoded
    }
}
