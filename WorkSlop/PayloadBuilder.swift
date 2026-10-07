import Foundation

/// One staging file built from the staged features.
struct BuiltFile: Identifiable {
    var id: String { restorePath }
    let domain: String
    let restorePath: String
    let keys: [String]
    let url: URL
}

struct BuiltPayload {
    let files: [BuiltFile]
    let warnings: [String]
}

/// Builds the real staging payload from the staged feature IDs, using
/// PayloadSpec.swift (verbatim desktop write targets). Writes are
/// grouped per target file and serialized as plist files inside the
/// app container, so what Apply *would* send is inspectable on disk.
///
/// Two honesty rules enforced here:
/// - Features whose payload needs user-supplied material (Status Bar
///   struct fields, Custom Icons theme choice) are NOT guessed: they
///   are reported as warnings and left out of the bundle.
/// - `lg-latest` merges into the device's live plists on desktop. That
///   merge base only exists during a real restore session, so the
///   preview bundle is built from an empty base and says so. Fail
///   closed, never invent a base.
///
/// Building files locally is real; sending them to the system is the
/// restore engine's job, which is not connected yet (see ApplyBar).
enum PayloadBuilder {
    static func build(staged: Set<String>) -> BuiltPayload {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PayloadPreview", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var grouped: [String: (domain: String, values: [String: Any], write: PayloadWrite)] = [:]
        var warnings: [String] = []

        for spec in PayloadSpecCatalog.all where staged.contains(spec.featureID) {
            for write in spec.writes {
                if let target = write.fileTarget {
                    warnings.append("\(spec.featureID): targets \(target) — depends on a desktop page setting, toggle alone has no fixed payload.")
                    continue
                }
                guard let key = write.key, let value = write.value else { continue }
                switch value {
                case .userSuppliedString(let field), .userSuppliedData(let field):
                    warnings.append("\(spec.featureID): \(key) needs \(field) picked first — not staged.")
                    continue
                default:
                    break
                }
                let groupKey = write.restorePath
                var entry = grouped[groupKey] ?? (write.domain.rawValue, [:], write)
                entry.values[key] = plistValue(value)
                grouped[groupKey] = entry
            }
        }

        var files: [BuiltFile] = []
        for (path, entry) in grouped.sorted(by: { $0.key < $1.key }) {
            guard let data = try? PropertyListSerialization.data(
                fromPropertyList: entry.values, format: .xml, options: 0) else { continue }
            let safeName = path.replacingOccurrences(of: "/", with: "_")
            let url = dir.appendingPathComponent(safeName)
            do {
                try data.write(to: url, options: .atomic)
                files.append(BuiltFile(
                    domain: entry.domain, restorePath: path,
                    keys: entry.values.keys.sorted(), url: url))
            } catch {
                warnings.append("\(path): could not write preview file (\(error.localizedDescription)).")
            }
        }
        return BuiltPayload(files: files, warnings: warnings)
    }

    private static func plistValue(_ value: PayloadValue) -> Any {
        switch value {
        case .bool(let b): return b
        case .int(let i): return i
        case .string(let s): return s
        case .userSuppliedString, .userSuppliedData: return ""
        }
    }
}
