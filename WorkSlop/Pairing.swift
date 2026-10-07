import Foundation

/// The pairing record is the .plist produced by idevicepair
/// (`idevicepair pair` writes a pairing record plist). The user imports
/// that file once; the app stores it in its own container and uses it to
/// open the local lockdown session for the backup/restore engine.
///
/// Nothing here talks to the device yet: import + validation only. The
/// loopback restore engine is wired behind this store once its
/// verification spike passes.
enum PairingStore {
    static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pairing.plist")
    }

    static var isImported: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Minimal structural validation: a real idevicepair record is a plist
    /// dict carrying the device certificate + private key material. We only
    /// check the shape here; cryptographic use belongs to the engine.
    static func validate(_ data: Data) -> Bool {
        guard let obj = try? PropertyListSerialization.propertyList(
            from: data, options: [], format: nil),
              let dict = obj as? [String: Any] else { return false }
        return dict["DeviceCertificate"] != nil
            && dict["HostPrivateKey"] != nil
            && dict["RootCertificate"] != nil
    }

    static func save(_ data: Data) throws {
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
