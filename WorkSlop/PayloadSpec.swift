import Foundation

// PayloadSpec.swift
//
// The desktop WorkSlop write targets for the mobile catalog IDs in
// Feature.swift, extracted verbatim from the desktop tree (citations
// per entry). PayloadBuilder builds real staging files from this data.
// Sending them to the system still rides the restore engine, which is
// not connected yet — see ApplyBar.
//
// How to read the desktop citations:
// - A registry entry written with `_t(...)` and no explicit `value=` uses
//   `TweakSpec.value == true` (src/tweaks/registry.py:51), and the loader
//   builds `BasicPlistTweak(spec.location, spec.key, value=spec.value)`
//   (src/tweaks/tweak_loader.py:107-121). Those writes are recorded below
//   as `.bool(true)`.
// - `GP` in the desktop registry is `FileLocation.globalPreferences`
//   (src/tweaks/registry.py:105).
// - Backup domains follow the desktop path mapping:
//   `/var/Managed Preferences/` -> ManagedPreferencesDomain,
//   `/var/mobile/` -> HomeDomain, and `/var/db/` -> DatabaseDomain
//   (src/restore/path_mapping.py:15,19-20).
// - `filePath` is the absolute on-device path. `restorePath` is the
//   domain-relative restore path used with the stated backup domain.

enum PayloadDomain: String, Equatable {
    case homeDomain = "HomeDomain"
    case appDomainPosterBoard = "AppDomain-com.apple.PosterBoard"
    case managedPreferencesDomain = "ManagedPreferencesDomain"
    case databaseDomain = "DatabaseDomain"
}

enum PayloadLocation: Equatable {
    /// A desktop `FileLocation` enum member; the associated value is the
    /// member name exactly as used by the desktop code.
    case fileLocation(member: String)
    /// A concrete HomeDomain restore path that is not expressed as a
    /// registry `FileLocation` member for this write.
    case directRestorePath
    /// A HomeDomain WebClip folder whose concrete name depends on the
    /// selected app bundle ID and sanitized display name.
    case parameterizedWebClipFolder
}

enum PayloadValue: Equatable {
    case bool(Bool)
    case int(Int)
    case string(String)
    /// A string that must be supplied by a user selection at apply time.
    case userSuppliedString(field: String)
    /// Binary data that must be supplied by a user selection at apply time.
    case userSuppliedData(field: String)
}

struct PayloadWrite: Equatable {
    let domain: PayloadDomain
    let location: PayloadLocation
    let filePath: String
    let restorePath: String
    let key: String?
    let value: PayloadValue?
    let fileTarget: String?
    let condition: String?

    init(
        domain: PayloadDomain,
        location: PayloadLocation,
        filePath: String,
        restorePath: String,
        key: String? = nil,
        value: PayloadValue? = nil,
        fileTarget: String? = nil,
        condition: String? = nil
    ) {
        self.domain = domain
        self.location = location
        self.filePath = filePath
        self.restorePath = restorePath
        self.key = key
        self.value = value
        self.fileTarget = fileTarget
        self.condition = condition
    }
}

struct PayloadSpec: Equatable {
    let featureID: String
    let writes: [PayloadWrite]
    let note: String?

    init(featureID: String, writes: [PayloadWrite], note: String? = nil) {
        self.featureID = featureID
        self.writes = writes
        self.note = note
    }
}

enum PayloadSpecCatalog {
    static let all: [PayloadSpec] = [
        // Desktop: src/gui/ios/posterboard.py; src/tweaks/posterboard/posterboard_tweak.py.
        PayloadSpec(
            featureID: "pb-tendies",
            writes: [
                PayloadWrite(
                    domain: .appDomainPosterBoard,
                    location: .directRestorePath,
                    filePath: "AppDomain container / PRBPosterExtensionDataStore",
                    restorePath: "Library/Application Support/PRBPosterExtensionDataStore/<structure>/Extensions/<extension>/descriptors",
                    fileTarget: "User-imported .tendies descriptor files (AppDomain-com.apple.PosterBoard; descriptors mode only - the database is never touched in this mode). Cap: 10 descriptors. Structure version is 61 on iOS 26 (59 on older lines) and is read from the device during the targeted backup."
                )
            ]
        ),
        PayloadSpec(
            featureID: "pb-templates",
            writes: [
                PayloadWrite(
                    domain: .appDomainPosterBoard,
                    location: .directRestorePath,
                    filePath: "AppDomain container / PRBPosterExtensionDataStore",
                    restorePath: "Library/Application Support/PRBPosterExtensionDataStore/<structure>/Extensions/<extension>/descriptors",
                    fileTarget: "User-imported .batter template files (AppDomain-com.apple.PosterBoard on device)."
                )
            ]
        ),
        PayloadSpec(
            featureID: "pb-video",
            writes: [
                PayloadWrite(
                    domain: .appDomainPosterBoard,
                    location: .directRestorePath,
                    filePath: "AppDomain container / PRBPosterExtensionDataStore",
                    restorePath: "Library/Application Support/PRBPosterExtensionDataStore/<structure>/Extensions/<extension>/descriptors",
                    fileTarget: "Video wallpaper .tendies exported from a freeze-frame image + video (loop / reverse / foreground options)."
                )
            ]
        ),
        PayloadSpec(
            featureID: "pb-reset",
            writes: [
                PayloadWrite(
                    domain: .appDomainPosterBoard,
                    location: .directRestorePath,
                    filePath: "AppDomain container / PRBPosterExtensionDataStore",
                    restorePath: "Library/Application Support/PRBPosterExtensionDataStore/<structure>/Extensions/<extension>/descriptors",
                    fileTarget: "Reset: stages removal of the delivered descriptors; PosterBoard rebuilds itself. The database is not part of this mode."
                )
            ]
        ),

        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-thermalmonitord",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.thermalmonitord",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-ota",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.mobile.softwareupdated",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.OTATaskingAgent",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.softwareupdateservicesd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.mobile.NRDUpdated",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-usagetrackingagent",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.UsageTrackingAgent",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-gamecenter",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.gamed",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-atwakeup",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.atc.atwakeup",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-tips",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.tipsd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-vpn",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.racoon",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-chineselan",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.wapic",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.wifi.wapic",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-healthkit",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.healthd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-airprint",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.printd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-assistivetouch",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.assistivetouchd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-icloud",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.itunescloudd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-internettethering",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.MobileInternetSharing",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-passbook",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.passd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-spotlight",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.searchd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.corespotlightservice",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.spotlightknowledged",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.spotlightknowledged.updater",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.spotlight.IndexAgent",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-nanotimekit",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.nanotimekitcompaniond",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-voicecontrol",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.assistant_service",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.assistantd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.voiced",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-followup",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.followupd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-location",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.locationd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-wifianalytics",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.wifianalyticsd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-analyticshelper",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.analyticsd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.analyticsd.admin",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.analyticsd.events",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-callanalytics",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.rtcreportingd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-coreduet",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.coreduetd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-insight",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.insightd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-metrics",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.metricsd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-mediaexperience",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.mediaremoted",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-symptomsd",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.symptomsd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.symptomsd-app",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-statisticaldiagnostic",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.StatisticalDiagnosticService",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-wirelessdiagnostics",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.wirelessdiagnostics",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-duetheuristic",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.DuetHeuristic-BM",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.DuetHeuristic-BM.Baseband",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-duetexpert",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.duetexpertd",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-decisiond",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.decisiond",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-triald",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.triald",
                    value: .bool(true)
                )
            ]
        ),
        // Desktop: src/gui/ios/daemons.py; src/tweaks/daemons_tweak.py (labels).
        PayloadSpec(
            featureID: "dm-sociald",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.sociald",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:406-410;
        // src/tweaks/lg_latest.py:48-64,120-186;
        // src/tweaks/lg_disable.py:80-81.
        PayloadSpec(
            featureID: "lg-latest",
            writes: [
                PayloadWrite(
                    domain: .homeDomain,
                    location: .directRestorePath,
                    filePath: "/var/mobile/Library/Preferences/com.apple.SwiftUI.plist",
                    restorePath: "Library/Preferences/com.apple.SwiftUI.plist",
                    key: "SolariumForceFallback",
                    value: .bool(true),
                    condition: "Merged into the device's existing plist when present; the file may be created when absent."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferencesHomeDomain"),
                    filePath: "/var/mobile/Library/Preferences/.GlobalPreferences.plist",
                    restorePath: "Library/Preferences/.GlobalPreferences.plist",
                    key: "SBDisallowGlassTime",
                    value: .bool(true),
                    condition: "Requires the device's live .GlobalPreferences.plist as the merge base; fail closed without it."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferencesHomeDomain"),
                    filePath: "/var/mobile/Library/Preferences/.GlobalPreferences.plist",
                    restorePath: "Library/Preferences/.GlobalPreferences.plist",
                    key: "SBDisallowGlassButtons",
                    value: .bool(true),
                    condition: "Requires the device's live .GlobalPreferences.plist as the merge base; fail closed without it."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .directRestorePath,
                    filePath: "/var/mobile/Library/Preferences/com.apple.springboard.plist",
                    restorePath: "Library/Preferences/com.apple.springboard.plist",
                    key: "SBDisableSpecularEverywhereUsingLSSAssertion",
                    value: .bool(true),
                    condition: "Merged into the device's existing plist when present; the payload must remain a non-empty, parseable plist and must never be zero bytes."
                )
            ],
            note: "Three-file Liquid Glass (Latest) payload. The registry entry is only the staging marker; the real writes are the four keys above."
        ),

        // Desktop: src/tweaks/registry.py:251;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-force-fallback",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SolariumForceFallback",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:253;
        // src/tweaks/basic_plist_locations.py:20.

        // Desktop: src/tweaks/registry.py:255;
        // src/tweaks/basic_plist_locations.py:27.
        PayloadSpec(
            featureID: "lg-legibility-2",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.uikit"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.UIKit.plist",
                    restorePath: "mobile/com.apple.UIKit.plist",
                    key: "UIViewGlassLegibilitySetting",
                    value: .int(2)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:259;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disallow-clock",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBDisallowGlassTime",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:261;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-dock",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBDisableGlassDock",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:263;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-flat-icons",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBUseFlatIconsEverywhere",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:265;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-widget-specular",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBDisableWidgetSpecular",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:267;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-dock-specular",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBDisableDockSpecular",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:269;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-folder-specular",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBDisableFolderSpecular",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:271;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-exclude-clear-shadows",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBExcludeAllClearGlassShadows",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:277;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-refraction",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SolariumDisableOuterRefraction",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:279;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-hdr",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SolariumAllowHDR",
                    value: .bool(false)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:283;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-disable-specular-everywhere",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBDisableSpecularEverywhere",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:317;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "lg-blurr-motion",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SolariumIncreasedDiffusion",
                    value: .bool(true)
                )
            ]
        ),


        PayloadSpec(
            featureID: "dm-rec-crashreports",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.ReportCrash",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.ReportCrash.Jetsam",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.ReportMemoryException",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.OTACrashCopier",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.analyticsd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.wifianalyticsd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.aslmanager",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.coresymbolicationd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.crash_mover",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.crashreportcopymobile",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.DumpBasebandCrash",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.DumpPanic",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd.admin",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd.events",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd.watchdog",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd_helper",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd_reporter",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.logd_reporter.report_statistics",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.system.logger",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.hangreporter",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.hangtracerd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.spindump",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.tailspind",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.rtcreportingd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.syslogd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.signpost.signpost_reporter",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.pluginkit.pkreporter",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.ProxiedCrashCopier",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.ProxiedCrashCopier.ProxyingDevice",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.ReportSystemMemory",
                    value: .bool(true)
                ),
            ]
        ),
        PayloadSpec(
            featureID: "dm-rec-diagnostics",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.diagnosticd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.diagnosticextensionsd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.diagnosticservicesd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.diagnosticspushd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.symptomsd-diag",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.sysdiagnose",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.sysdiagnose.darwinos",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.sysdiagnose_helper",
                    value: .bool(true)
                ),
            ]
        ),
        PayloadSpec(
            featureID: "dm-rec-appleads",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.promotedcontentd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.adprivacyd",
                    value: .bool(true)
                ),
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.adservicesd",
                    value: .bool(true)
                ),
            ]
        ),
        PayloadSpec(
            featureID: "dm-rec-feedback",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.feedbackd",
                    value: .bool(true)
                ),
            ]
        ),
        PayloadSpec(
            featureID: "dm-rec-shazam",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.shazamd",
                    value: .bool(true)
                ),
            ]
        ),
        PayloadSpec(
            featureID: "dm-rec-settingsstats",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.settings-statsd",
                    value: .bool(true)
                ),
            ]
        ),

        // Desktop: src/tweaks/status_bar/status_bar_tweak.py:75-84;
        // src/tweaks/status_bar/status_setter.py:182-195,279-281;
        // src/devicemanagement/device_manager.py:2314-2336.
        PayloadSpec(
            featureID: "status-bar",
            writes: [
                PayloadWrite(
                    domain: .homeDomain,
                    location: .directRestorePath,
                    filePath: "/var/mobile/Library/SpringBoard/statusBarOverrides",
                    restorePath: "Library/SpringBoard/statusBarOverrides",
                    fileTarget: "Serialized StatusBarOverrideData struct (3,944 bytes), generated from the desktop StatusBar override state; not a plist and not a single fixed key/value.",
                    condition: "Classic pre-iOS 27 (iOS 26.x) branch. iOS 27 keeps carrier text only."
                )
            ],
            note: "The desktop target and serialization size are pinned, but the mobile toggle alone does not specify the individual field values inside the struct."
        ),

        // Desktop: src/tweaks/registry.py:80-92,133-135;
        // src/tweaks/tweak_classes.py:83-129;
        // src/tweaks/basic_plist_locations.py:11.
        PayloadSpec(
            featureID: "sb-watchos-pairing",
            writes: [
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "IOS_PAIRING_EOL_MIN_PAIRING_COMPATIBILITY_VERSION_CHIPIDS",
                    value: .string("")
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "maxPairingCompatibilityVersion",
                    value: .int(37)
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "lastRestoreIdentifier",
                    value: .string("CD97EEB8-BCD2-486B-BC13-C384E6B916C4")
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "minPairingCompatibilityVersionWithChipID",
                    value: .int(1)
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "lastRestoreIdentifier_state",
                    value: .int(0)
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "AdvertisingIdentifierSeed",
                    value: .string("85E70251-1960-4DA0-A321-B68AC118FAB5")
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .fileLocation(member: "FileLocation.nanoregistry"),
                    filePath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist",
                    restorePath: "Library/Preferences/com.apple.NanoRegistry.plist",
                    key: "minPairingCompatibilityVersion",
                    value: .int(1)
                )
            ],
            note: "AdvancedPlistTweak factory write; there is no single registry key for this feature."
        ),

        // Desktop: src/tweaks/registry.py:136-137;
        // src/tweaks/basic_plist_locations.py:10.

        // Desktop: src/tweaks/registry.py:139-140;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-dont-lock-crash",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBDontLockAfterCrash",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:142-143;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-dont-dim-ac",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBDontDimOrLockOnAC",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:145-146;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-hide-low-power",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBHideLowPowerAlerts",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:148-149;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-hide-ac-power",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBHideACPower",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:151-152;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-never-breadcrumb",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBNeverBreadcrumb",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:154-155;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-supervision-text",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBShowSupervisionTextOnLockScreen",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:176-177;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-icon-parallax",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBDisableParallax",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:183-184;
        // src/tweaks/basic_plist_locations.py:8.
        PayloadSpec(
            featureID: "sb-hide-search",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.springboard"),
                    filePath: "/var/Managed Preferences/mobile/com.apple.springboard.plist",
                    restorePath: "mobile/com.apple.springboard.plist",
                    key: "SBHomeScreenShowsSearchAffordance",
                    value: .bool(false)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:188;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "in-build-version",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "UIStatusBarShowBuildVersion",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:190-191;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "in-rtl",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "NSForceRightToLeftWritingDirection",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:193-194;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "in-ltr",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "NSForceLeftToRightWritingDirection",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:196-211;
        // src/tweaks/basic_plist_locations.py:45;
        // src/tweaks/tweak_classes.py:118-129.
        PayloadSpec(
            featureID: "in-disable-thermal",
            writes: [
                PayloadWrite(
                    domain: .databaseDomain,
                    location: .fileLocation(member: "FileLocation.disabledDaemons"),
                    filePath: "/var/db/com.apple.xpc.launchd/disabled.plist",
                    restorePath: "com.apple.xpc.launchd/disabled.plist",
                    key: "com.apple.thermalmonitord",
                    value: .bool(true)
                )
            ],
            note: "This feature writes one key into the shared launchd disabled.plist; the desktop apply pass merges other disabled-daemon keys into the same file."
        ),

        // Desktop: src/tweaks/registry.py:214;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "in-hidden-icons",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "SBIconVisibility",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:224-225;
        // src/tweaks/basic_plist_locations.py:20.
        PayloadSpec(
            featureID: "in-key-flicks",
            writes: [
                PayloadWrite(
                    domain: .managedPreferencesDomain,
                    location: .fileLocation(member: "FileLocation.globalPreferences"),
                    filePath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist",
                    restorePath: "mobile/.GlobalPreferences.plist",
                    key: "GesturesEnabled",
                    value: .bool(true)
                )
            ]
        ),

        // Desktop: src/tweaks/registry.py:227;
        // src/tweaks/basic_plist_locations.py:20.

        // Desktop: src/tweaks/registry.py:216;
        // src/tweaks/basic_plist_locations.py:20.

        // Desktop: src/tweaks/registry.py:231;
        // src/tweaks/basic_plist_locations.py:22.

        // Desktop: src/tweaks/registry.py:233;
        // src/tweaks/basic_plist_locations.py:26.

        // Desktop: src/tweaks/icon_themes/icon_theme.py:4-21;
        // src/tweaks/icon_themes/icon_themes_tweak.py:38-57,241-277.
        PayloadSpec(
            featureID: "custom-icons",
            writes: [
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "ApplicationBundleIdentifier",
                    value: .userSuppliedString(field: "selected app bundle ID"),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "ApplicationBundleVersion",
                    value: .int(1),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "ClassicMode",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "ConfigurationIsManaged",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "ContentMode",
                    value: .string("UIWebClipContentModeRecommended"),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "FullScreen",
                    value: .bool(true),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "IconIsPrecomposed",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "IconIsScreenShotBased",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "IgnoreManifestScope",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "IsAppClip",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "Orientations",
                    value: .int(0),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "ScenelessBackgroundLaunch",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "Title",
                    value: .userSuppliedString(field: "sanitized selected display name"),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "WebClipStatusBarStyle",
                    value: .string("UIWebClipStatusBarStyleDefault"),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/Info.plist",
                    key: "RemovalDisallowed",
                    value: .bool(false),
                    condition: "Written once for each selected app/icon theme."
                ),
                PayloadWrite(
                    domain: .homeDomain,
                    location: .parameterizedWebClipFolder,
                    filePath: "/var/mobile/Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/icon.png",
                    restorePath: "Library/WebClips/Cowabunga_<bundleID>,<sanitizedDisplayName>.webclip/icon.png",
                    value: .userSuppliedData(field: "selected app icon image bytes"),
                    fileTarget: "icon.png containing the selected app icon image bytes.",
                    condition: "Written once for each selected app/icon theme that has icon data; themes without icon data are skipped after their Info.plist has been staged by the desktop code."
                )
            ],
            note: "No write occurs until at least one app/icon theme is selected. The concrete folder path, bundle ID, display name, and icon bytes cannot be pinned from the mobile toggle alone."
        )
    ]

    static let byFeatureID: [String: PayloadSpec] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.featureID, $0) }
    )
}
