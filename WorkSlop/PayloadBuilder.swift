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
/// restore engine's job, which is not connected yet.
enum PayloadBuilder {
    static func build(staged: Set<String>) -> BuiltPayload {
        build(staged: staged, iconEntries: CustomIconStore.load())
    }

    static func build(staged: Set<String>, iconEntries: [CustomIconEntry]) -> BuiltPayload {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PayloadPreview", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var grouped: [String: (domain: String, values: [String: Any], write: PayloadWrite)] = [:]
        var warnings: [String] = []

        for spec in PayloadSpecCatalog.all where staged.contains(spec.featureID) {
            for write in spec.writes {
                if let target = write.fileTarget {
                    // pb-reset and dm-clear-screentime ARE handled by
                    // the dedicated zero-byte blocks below - warning
                    // here would contradict the files actually built.
                    if spec.featureID != "pb-reset" && spec.featureID != "dm-clear-screentime" {
                        warnings.append("\(spec.featureID): targets \(target) - depends on a desktop page setting, toggle alone has no fixed payload.")
                    }
                    continue
                }
                if write.restorePath.contains("<") {
                    // Parameterized per-entry target (e.g. Custom
                    // Icons WebClip folders): real paths come from
                    // the dedicated blocks below - never write a
                    // literal placeholder path.
                    continue
                }
                if let condition = write.condition {
                    warnings.append("\(spec.featureID): \(write.key ?? "write") is conditional - \(condition) Preview here starts from an empty base only.")
                }
                guard let key = write.key, let value = write.value else { continue }
                switch value {
                case .userSuppliedString(let field), .userSuppliedData(let field):
                    warnings.append("\(spec.featureID): \(key) needs \(field) picked first — not staged.")
                    continue
                default:
                    break
                }
                let groupKey = write.domain.rawValue + "|" + write.restorePath
                var entry = grouped[groupKey] ?? (write.domain.rawValue, [:], write)
                entry.values[key] = plistValue(value)
                grouped[groupKey] = entry
            }
        }

        // Desktop seed: any Daemons apply also carries the six
        // upstream always-included daemon states
        // (daemons_tweak.py:220-227, loaded in tweak_loader.py).
        // ftp-proxy-embedded is false on purpose - verbatim.
        let daemonSeeds: [String: Any] = [
            "com.apple.magicswitchd.companion": true,
            "com.apple.security.otpaird": true,
            "com.apple.dhcp6d": true,
            "com.apple.bootpd": true,
            "com.apple.ftp-proxy-embedded": false,
            "com.apple.relevanced": true,
        ]
        for (groupKey, entry) in grouped
        where groupKey.hasSuffix("|com.apple.xpc.launchd/disabled.plist") {
            var merged = grouped[groupKey]!
            for (k, v) in daemonSeeds where merged.values[k] == nil {
                merged.values[k] = v
            }
            grouped[groupKey] = merged
            warnings.append("disabled.plist also carries the desktop's six always-included daemon seed states (one of them, ftp-proxy-embedded, is false on desktop).")
        }

        var files: [BuiltFile] = []

        // Custom Icons delivery (desktop icon_themes_tweak.py):
        // one WebClip folder per entry with a bundle ID. The desktop
        // sanitizes the display name by turning "," and "/" into
        // spaces, an empty name is legal (hidden label), a later theme
        // for the same bundle REPLACES the earlier one, Info.plist is
        // always written, and icon.png only when icon data exists.
        if staged.contains("custom-icons") {
            var byBundle: [String: CustomIconEntry] = [:]
            var order: [String] = []
            for entry in iconEntries where !entry.bundleID.isEmpty {
                if byBundle[entry.bundleID] == nil { order.append(entry.bundleID) }
                byBundle[entry.bundleID] = entry // replace, like desktop add_theme
            }
            if order.isEmpty {
                warnings.append("custom-icons: no entries with a bundle ID - nothing staged.")
            }
            for bundle in order {
                let entry = byBundle[bundle]!
                let safeName = entry.appName
                    .replacingOccurrences(of: ",", with: " ")
                    .replacingOccurrences(of: "/", with: " ")
                let folder = "Library/WebClips/Cowabunga_\(entry.bundleID),\(safeName).webclip"
                // Cowabunga makeInfoPlist, verbatim (icon_themes_tweak.py:39-57).
                let plist: [String: Any] = [
                    "ApplicationBundleIdentifier": entry.bundleID,
                    "ApplicationBundleVersion": 1,
                    "ClassicMode": false,
                    "ConfigurationIsManaged": false,
                    "ContentMode": "UIWebClipContentModeRecommended",
                    "FullScreen": true,
                    "IconIsPrecomposed": false,
                    "IconIsScreenShotBased": false,
                    "IgnoreManifestScope": false,
                    "IsAppClip": false,
                    "Orientations": 0,
                    "ScenelessBackgroundLaunch": false,
                    "Title": safeName,
                    "WebClipStatusBarStyle": "UIWebClipStatusBarStyleDefault",
                    "RemovalDisallowed": false,
                ]
                if let plistData = try? PropertyListSerialization.data(
                    fromPropertyList: plist, format: .xml, options: 0) {
                    let url = dir.appendingPathComponent(
                        folder.replacingOccurrences(of: "/", with: "_") + "_Info.plist")
                    try? plistData.write(to: url, options: .atomic)
                    files.append(BuiltFile(
                        domain: "HomeDomain", restorePath: folder + "/Info.plist",
                        keys: Array(plist.keys).sorted(), url: url))
                }
                if let png = entry.imageData {
                    let url = dir.appendingPathComponent(
                        folder.replacingOccurrences(of: "/", with: "_") + "_icon.png")
                    try? png.write(to: url, options: .atomic)
                    files.append(BuiltFile(
                        domain: "HomeDomain", restorePath: folder + "/icon.png",
                        keys: ["icon.png (\(png.count) bytes)"], url: url))
                } else {
                    warnings.append("custom-icons: skipped icon file for \(entry.bundleID) (no icon data) - Info.plist still staged, like desktop.")
                }
            }
        }

        // PosterBoard reset (desktop posterboard_tweak.py): real
        // zero-byte files for the descriptor folders + GalleryCache,
        // structure version resolved by PayloadSpecCatalog.pbStructure.
        if staged.contains("pb-reset"),
           let resetSpec = PayloadSpecCatalog.all.first(where: { $0.featureID == "pb-reset" }) {
            for write in resetSpec.writes {
                let url = dir.appendingPathComponent(
                    write.restorePath.replacingOccurrences(of: "/", with: "_") + ".empty")
                try? Data().write(to: url, options: .atomic)
                files.append(BuiltFile(
                    domain: write.domain.rawValue, restorePath: write.restorePath,
                    keys: ["<empty file, 0 bytes>"], url: url))
            }
        }

        // Clear ScreenTimeAgent (desktop NullifyFileTweak on
        // FileLocation.screentime, tweak_loader.py:171): the plist
        // is delivered EMPTY (zero bytes); ScreenTimeAgent rebuilds
        // it from scratch.
        if staged.contains("dm-clear-screentime"),
           let stSpec = PayloadSpecCatalog.all.first(where: { $0.featureID == "dm-clear-screentime" }) {
            for write in stSpec.writes {
                let url = dir.appendingPathComponent(
                    write.restorePath.replacingOccurrences(of: "/", with: "_") + ".empty")
                try? Data().write(to: url, options: .atomic)
                files.append(BuiltFile(
                    domain: write.domain.rawValue, restorePath: write.restorePath,
                    keys: ["<empty file, 0 bytes>"], url: url))
            }
        }

        for (groupKey, entry) in grouped.sorted(by: { $0.key < $1.key }) {
            let path = String(groupKey.drop(while: { $0 != "|" }).dropFirst())
            guard let data = try? PropertyListSerialization.data(
                fromPropertyList: entry.values, format: .xml, options: 0) else {
                warnings.append("\(path): could not serialize - skipped.")
                continue
            }
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
