import SwiftUI

/// WorkSlop brand tokens — mirrors the desktop app: strong (not pale)
/// blue/white, rounded brand tile with bold white "WS".
enum Brand {
    static let blue = Color(red: 0.02, green: 0.32, blue: 0.85)
    static let blueStrong = Color(red: 0.0, green: 0.25, blue: 0.75)
    static let tileCorner: CGFloat = 18
}

/// The three UI variants the desktop ships (Settings → Tampilan).
/// Switching the picker really re-themes the app: tint color, brand
/// tile fill, and corner accents change per variant.
enum UIStyle: String, CaseIterable {
    case workslop
    case nugget
    case modern

    var displayName: String {
        switch self {
        case .workslop: return "WorkSlop"
        case .nugget: return "Nugget"
        case .modern: return "Nugget Modern (Main)"
        }
    }

    var tint: Color {
        switch self {
        case .workslop: return Brand.blue
        case .nugget: return Color(red: 0.55, green: 0.60, blue: 0.70)
        case .modern: return Color(red: 0.45, green: 0.30, blue: 0.95)
        }
    }

    /// The WorkSlop app-icon color that follows this UI: purple for
    /// the main (Nugget Modern) UI, blue second, gray third. Drives
    /// the in-app brand tile and the Home Screen alternate icon.
    var iconColorName: String {
        switch self {
        case .workslop: return "IconBlue"
        case .nugget: return "IconGray"
        case .modern: return "IconPurple"
        }
    }

    /// The three UIs have different layouts, not just colors:
    /// main (blue) = drifting-Apple backdrop + big cards;
    /// Nugget (black/gray) = plain dark-gray backdrop, compact rows;
    /// Nugget Modern (purple) = drift backdrop, tile grid.
    var showsDrift: Bool { self != .nugget }

    var tabIcons: (home: String, lg: String, pages: String, settings: String) {
        switch self {
        case .workslop:
            return ("house.fill", "square.stack.3d.up.fill",
                    "slider.horizontal.3", "gearshape.fill")
        case .nugget:
            return ("house", "square.stack.3d.up",
                    "wrench.and.screwdriver", "gearshape")
        case .modern:
            return ("square.grid.2x2.fill", "sparkles",
                    "slider.horizontal.below.rectangle", "gearshape.2.fill")
        }
    }

    var tileCornerScale: CGFloat {
        switch self {
        case .workslop: return 1.0
        case .nugget: return 0.7
        case .modern: return 1.4
        }
    }
}

struct BrandTile: View {
    var size: CGFloat = 54
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @AppStorage("glassUI") private var glassUI = true

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    private var base: Color {
        switch style {
        case .workslop: return Brand.blue
        case .nugget: return Color(red: 0.22, green: 0.23, blue: 0.27)
        case .modern: return Color(red: 0.45, green: 0.30, blue: 0.95)
        }
    }

    var body: some View {
        ZStack {
            if glassUI {
                LinearGradient(
                    colors: [base.opacity(0.85), base],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                base
            }
            Text("WS")
                .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(
            cornerRadius: size * 0.26, style: .continuous))
    }
}

/// Drifting Apple-logo backdrop, mirroring the desktop v4 UI's Sky
/// background: faint "apple.logo" watermarks slowly floating and
/// turning behind the content. Static when Reduce Motion is on.
/// App appearance choice on Home for iOS 26/27: the app can run with
/// the Liquid Glass look, or flat ("No Liquid Glass" = plain system
/// surfaces). When the glass look is off, backgrounds render flat and
/// the UI-style choice in Settings is blocked.
enum AppAppearance {
    static var glassUI: Bool {
        UserDefaults.standard.object(forKey: "glassUI") as? Bool ?? true
    }
}

struct AppleDriftBackground: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @AppStorage("glassUI") private var glassUI = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }
    private var tint: Color { style.tint }

    private struct Mote {
        let x, y, size, delay, duration, travel, spin: Double
    }

    private let motes: [Mote] = [
        Mote(x: 0.12, y: 0.10, size: 64, delay: 0.0, duration: 9, travel: 22, spin: 7),
        Mote(x: 0.82, y: 0.07, size: 42, delay: 1.2, duration: 11, travel: 30, spin: -9),
        Mote(x: 0.55, y: 0.28, size: 30, delay: 0.6, duration: 8, travel: 18, spin: 11),
        Mote(x: 0.25, y: 0.42, size: 48, delay: 2.0, duration: 12, travel: 26, spin: -6),
        Mote(x: 0.88, y: 0.48, size: 72, delay: 0.3, duration: 10, travel: 20, spin: 5),
        Mote(x: 0.08, y: 0.66, size: 36, delay: 1.6, duration: 9, travel: 28, spin: -12),
        Mote(x: 0.45, y: 0.72, size: 58, delay: 0.9, duration: 13, travel: 16, spin: 8),
        Mote(x: 0.72, y: 0.86, size: 40, delay: 2.4, duration: 10, travel: 24, spin: -7),
        Mote(x: 0.20, y: 0.92, size: 52, delay: 1.1, duration: 11, travel: 20, spin: 10),
        Mote(x: 0.95, y: 0.24, size: 28, delay: 0.5, duration: 8, travel: 15, spin: -10),
    ]

    var body: some View {
        if !glassUI {
            Color(UIColor.systemBackground).ignoresSafeArea()
        } else {
            glassBody
        }
    }

    private var glassBody: some View {
        GeometryReader { geo in
            ZStack {
                if style.showsDrift {
                    LinearGradient(
                        colors: [tint.opacity(0.12), tint.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom)
                } else {
                    LinearGradient(
                        colors: [Color(white: 0.13), Color(white: 0.08)],
                        startPoint: .top, endPoint: .bottom)
                }
                if style.showsDrift {
                ForEach(motes.indices, id: \.self) { i in
                    let m = motes[i]
                    Image(systemName: "apple.logo")
                        .font(.system(size: m.size))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .position(x: geo.size.width * m.x,
                                  y: geo.size.height * m.y)
                        .offset(y: drift && !reduceMotion ? -m.travel : m.travel)
                        .rotationEffect(.degrees(
                            drift && !reduceMotion ? m.spin : -m.spin))
                        .animation(
                            reduceMotion
                                ? nil
                                : .easeInOut(duration: m.duration)
                                    .repeatForever(autoreverses: true)
                                    .delay(m.delay),
                            value: drift)
                }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear { drift = true }
    }
}

/// Honest status chip used wherever a feature's on-device effect or its
/// delivery engine is not yet proven on a real device.
struct StatusChip: View {
    let text: String
    var warn: Bool = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((warn ? Color.orange : Color.secondary).opacity(0.18))
            .foregroundStyle(warn ? Color.orange : Color.secondary)
            .clipShape(Capsule())
    }
}
