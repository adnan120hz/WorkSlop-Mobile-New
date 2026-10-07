import Foundation

/// Delivery route a tweak rides on iOS 26. Everything stages through the
/// partial (sparse) restore EXCEPT the S8 "Liquid Glass (Terbaru)" tweak,
/// which rides a full backup -> modify -> restore with all data, exactly
/// like the desktop. (The desktop's old Beta 1 tweaks were removed by
/// the maintainer and do not exist here.)
enum DeliveryRoute: String {
    case partialRestore = "Partial restore"
    case fullBackup = "Full backup → modify → restore"
}

/// iOS version window a feature supports. A feature is locked ONLY when
/// the device's iOS is outside its window — when the iOS supports it, the
/// feature is open, exactly like the desktop app. (The app runs on the
/// device it tweaks, so "the device" is this phone.)
struct IOSWindow {
    let min: (major: Int, minor: Int)
    let maxExclusive: (major: Int, minor: Int)?

    func contains(_ v: (major: Int, minor: Int)) -> Bool {
        if v.major != min.major { return v.major > min.major }
        if v.minor < min.minor { return false }
        if let max = maxExclusive {
            if v.major != max.major { return v.major < max.major }
            if v.minor >= max.minor { return false }
        }
        return true
    }

    var label: String {
        if let max = maxExclusive {
            return "iOS \(min.major).\(min.minor)–<\(max.major).\(max.minor)"
        }
        return "iOS \(min.major).\(min.minor)+"
    }
}

enum Availability: Equatable {
    case supported
    case unsupported(reason: String)

    var isEnabled: Bool {
        if case .supported = self { return true }
        return false
    }

    var chipText: String? {
        switch self {
        case .supported: return nil
        case .unsupported(let reason): return reason
        }
    }
}

struct Feature: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let section: String
    let route: DeliveryRoute
    let window: IOSWindow

    func availability(for ios: (major: Int, minor: Int)) -> Availability {
        window.contains(ios)
            ? .supported
            : .unsupported(reason: "Butuh \(window.label)")
    }
}

enum DeviceInfo {
    /// This device's iOS version. The UI tests pass -DemoIOS26 so the
    /// recorded tour demonstrates the supported (open) state; real runs
    /// always read the actual system version.
    static var iosVersion: (major: Int, minor: Int) {
        if ProcessInfo.processInfo.arguments.contains("-DemoIOS26") {
            return (26, 6)
        }
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return (v.majorVersion, v.minorVersion)
    }
}

/// Staged (toggled-on) selections, persisted like the desktop's tweak
/// staging. Staging is selection only: nothing is delivered until the
/// on-device restore engine is verified — see ApplyBar.
final class SelectionStore: ObservableObject {
    @Published private(set) var staged: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(staged), forKey: "stagedFeatures")
        }
    }

    init() {
        staged = Set(UserDefaults.standard.stringArray(forKey: "stagedFeatures") ?? [])
    }

    func isOn(_ id: String) -> Bool { staged.contains(id) }

    func set(_ id: String, _ on: Bool) {
        if on { staged.insert(id) } else { staged.remove(id) }
        objectWillChange.send()
    }
}

enum FeatureCatalog {
    /// Solarium exists only on iOS 26; the desktop Liquid Glass sets are
    /// iOS 26 tweaks. The full-backup route is proven for 26.6.x builds,
    /// so the window closes before 26.7.
    private static let ios26 = IOSWindow(min: (26, 0), maxExclusive: (26, 7))
    private static let ios18plus = IOSWindow(min: (18, 0), maxExclusive: nil)

    /// Mirrors the desktop registry sections/titles (Liquid Glass,
    /// SpringBoard, Internal Options) plus the desktop Status Bar and
    /// Custom Icons pages. Titles are the desktop's; subtitles name the
    /// plist key each toggle stages. The desktop "Feature Flags" section
    /// is deliberately absent: that delivery channel is proven closed on
    /// retail iOS 26.6.1, so it cannot be honestly offered here.
    static let all: [Feature] = [
        // --- Liquid Glass (Terbaru) — the S8 payload, full-backup route.
        // SolariumForceFallback is read live by DesignLibrary from
        // com.apple.SwiftUI on iOS 26.6.1 (firmware-verified); the
        // on-screen effect is still a device-test question.
        Feature(
            id: "lg-latest",
            title: "Liquid Glass (Terbaru)",
            subtitle: "SolariumForceFallback → com.apple.SwiftUI.plist + 2 key lock-screen + specular",
            section: "Liquid Glass",
            route: .fullBackup,
            window: ios26),

        // --- Liquid Glass (regular set, partial restore) ---
        Feature(id: "lg-force-fallback", title: "Force Solarium Fallback",
                subtitle: "SolariumForceFallback", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-swiftui", title: "Disable Solarium (SwiftUI)",
                subtitle: "com.apple.SwiftUI.DisableSolarium", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-legibility-2", title: "Glass Legibility Value 2",
                subtitle: "UIViewGlassLegibilitySetting = 2", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disallow-clock", title: "Disallow Glass on LS Clock",
                subtitle: "SBDisallowGlassTime", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-dock", title: "Disable Glass on Dock",
                subtitle: "SBDisableGlassDock", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-flat-icons", title: "Flat Icons Everywhere",
                subtitle: "SBUseFlatIconsEverywhere", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-widget-specular", title: "Disable Widget Specular",
                subtitle: "SBDisableWidgetSpecular", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-dock-specular", title: "Disable Dock Specular",
                subtitle: "SBDisableDockSpecular", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-folder-specular", title: "Disable Folder Specular",
                subtitle: "SBDisableFolderSpecular", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-exclude-clear-shadows", title: "Exclude Clear Glass Shadows",
                subtitle: "SBExcludeAllClearGlassShadows", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-refraction", title: "Disable Outer Refraction",
                subtitle: "SolariumDisableOuterRefraction", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-hdr", title: "Disable Solarium HDR",
                subtitle: "SolariumAllowHDR = false", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-disable-specular-everywhere", title: "Disable Specular Everywhere",
                subtitle: "SBDisableSpecularEverywhere", section: "Liquid Glass",
                route: .partialRestore, window: ios26),
        Feature(id: "lg-blurr-motion", title: "Blurr Motion",
                subtitle: "SolariumIncreasedDiffusion", section: "Liquid Glass",
                route: .partialRestore, window: ios26),

        // --- Status Bar (desktop Status Bar page) ---
        Feature(
            id: "status-bar",
            title: "Status Bar",
            subtitle: "Carrier text, icons & overrides",
            section: "Status Bar",
            route: .partialRestore,
            window: ios18plus),

        // --- SpringBoard (desktop SpringBoard section) ---
        Feature(id: "sb-watchos-pairing", title: "Allow pairing with any watchOS version",
                subtitle: "WatchOSCompatibility", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-airdrop-limit", title: "Disable AirDrop Time Limit for Everyone Option",
                subtitle: "AirDropDisableTimeLimit", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-dont-lock-crash", title: "Disable Lock After Respring",
                subtitle: "SBDontLockAfterCrash", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-dont-dim-ac", title: "Disable Screen Dimming While Charging",
                subtitle: "SBDontDimOrLockOnAC", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-hide-low-power", title: "Disable Low Battery Alerts",
                subtitle: "SBHideLowPowerAlerts", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-hide-ac-power", title: "Hide AC Power on Lock Screen",
                subtitle: "SBHideACPower", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-never-breadcrumb", title: "Disable Breadcrumbs",
                subtitle: "SBNeverBreadcrumb", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-supervision-text", title: "Show Supervision Text on Lock Screen",
                subtitle: "SBShowSupervisionTextOnLockScreen", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-stage-manager-airplay", title: "Enable AirPlay support for Stage Manager",
                subtitle: "AirplaySupport", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-di-screenshots", title: "Show Dynamic Island in Screenshots",
                subtitle: "SBAlwaysShowSystemApertureInSnapshots", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-hide-di", title: "Hide Dynamic Island Completely",
                subtitle: "HideDICompletely", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-floating-tab-bar", title: "Disable Floating Tab Bar",
                subtitle: "UseFloatingTabBar = false", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-icon-parallax", title: "Disable Icon Parallax",
                subtitle: "SBDisableIconParallax", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),
        Feature(id: "sb-hide-search", title: "Hide Search Button on Home Screen",
                subtitle: "SBHideSearchAffordance", section: "SpringBoard",
                route: .partialRestore, window: ios18plus),

        // --- Internal Options (desktop Internal section) ---
        Feature(id: "in-build-version", title: "Show Build Version in Status Bar",
                subtitle: "UIStatusBarShowBuildVersion", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-rtl", title: "Force Right-to-Left Layout",
                subtitle: "NSForceRightToLeftWritingDirection", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-ltr", title: "Force Left-to-Right Layout",
                subtitle: "NSForceLeftToRightWritingDirection", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-disable-thermal", title: "Disable Thermal",
                subtitle: "DisableThermal", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-hidden-icons", title: "Show Hidden Icons on Home Screen",
                subtitle: "SBIconVisibility", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-key-flicks", title: "Keyboard Key Flicks",
                subtitle: "GesturesEnabled", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-clock-seconds", title: "Disable Clock Icon Seconds Hand",
                subtitle: "SBDisableClockIconSecondsHand", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-imessage-debug", title: "iMessage Debugging",
                subtitle: "iMessageDiagnosticsEnabled", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-appstore-debug", title: "App Store Debug Gesture",
                subtitle: "debugGestureEnabled", section: "Internal Options",
                route: .partialRestore, window: ios18plus),
        Feature(id: "in-notes-debug", title: "Notes Debug Mode",
                subtitle: "DebugModeEnabled", section: "Internal Options",
                route: .partialRestore, window: ios18plus),

        // --- Custom Icons (desktop Custom Icons page) ---
        Feature(
            id: "custom-icons",
            title: "Custom Icons",
            subtitle: "Icon themes & custom app icons",
            section: "Custom Icons",
            route: .partialRestore,
            window: ios18plus),
    ]

    static var sections: [String] {
        var seen: [String] = []
        for f in all where !seen.contains(f.section) { seen.append(f.section) }
        return seen
    }

    static func features(in section: String) -> [Feature] {
        all.filter { $0.section == section }
    }
}
