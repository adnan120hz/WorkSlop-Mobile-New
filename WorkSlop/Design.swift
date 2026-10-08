import SwiftUI

/// WorkSlop brand tokens — mirrors the desktop app: strong (not pale)
/// blue/white, rounded brand tile with bold white "WS".
/// The one card surface for the whole app, colored like the
/// approved reference UI - a pale wash of the UI tint on big fluid
/// corners, with a glossy reflection sheen and a soft tinted
/// shadow so menus read as polished glass, not flat blocks.
/// The Home "App appearance" choice drives it app-wide:
/// "Liquid Glass UI" = real iOS 26 glass; "No Liquid Glass" = the
/// flat pale cards of the reference screenshot. Nugget (dark)
/// gets the same treatment in slate instead of system-gray fill.
struct CardSurface: ViewModifier {
    let style: UIStyle
    let glass: Bool
    var radius: CGFloat = 32

    /// The user's appearance choice from Home (default: glass).
    @AppStorage("glassUI") private var glassUI = true

    private var effectiveGlass: Bool { glass && glassUI }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    /// Pale tint wash, matched to the reference screenshot: clearly
    /// the UI's color, never saturated and never plain white
    /// (except Nugget, which is dark by design).
    private var tintOpacity: Double {
        style == .nugget ? 0.22 : 0.16
    }

    func body(content: Content) -> some View {
        Group {
            if effectiveGlass {
                if #available(iOS 26.0, *) {
                    content
                        .glassEffect(.regular.tint(style.tint.opacity(tintOpacity)), in: shape)
                        .overlay { gloss }
                } else {
                    content
                        .background(.ultraThinMaterial, in: shape)
                        .overlay { shape.fill(style.tint.opacity(0.08)) }
                        .overlay { gloss }
                }
            } else {
                // No Liquid Glass: flat pale cards, matte, exactly
                // like the reference screenshot.
                content
                    .background(flatFill)
                    .clipShape(shape)
            }
        }
        .shadow(
            color: style == .nugget ? .clear : style.tint.opacity(0.10),
            radius: 16, x: 0, y: 6)
    }

    /// Glossy Liquid Glass reflections: a soft white sheen falling
    /// from the top edge, a bright rim on the upper border, and a
    /// faint tinted shade at the bottom - the polished-glass look.
    private var gloss: some View {
        ZStack {
            shape.fill(
                LinearGradient(
                    colors: [Color.white.opacity(style == .nugget ? 0.14 : 0.22),
                             Color.white.opacity(0.04),
                             Color.clear],
                    startPoint: .top, endPoint: .center))
            shape.fill(
                LinearGradient(
                    colors: [Color.clear, style.tint.opacity(0.05)],
                    startPoint: .center, endPoint: .bottom))
            shape.strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(style == .nugget ? 0.28 : 0.55),
                             Color.white.opacity(0.10),
                             style.tint.opacity(0.14)],
                    startPoint: .top, endPoint: .bottom),
                lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    private var flatFill: Color {
        style == .nugget
            ? Color(UIColor.secondarySystemBackground)
            : style.tint.opacity(0.13)
    }
}

extension View {
    /// Padded card using the current appearance (glass or flat).
    func cardSurface(_ style: UIStyle, glass: Bool, radius: CGFloat = 32) -> some View {
        modifier(CardSurface(style: style, glass: glass, radius: radius))
    }

    /// A List row rendered as a self-contained colored card, so no
    /// menu depends on list-style backgrounds to avoid white blocks.
    func cardedRow(_ style: UIStyle, glass: Bool) -> some View {
        padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardSurface(style: style, glass: glass))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
    }
}

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

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    /// The desktop WorkSlop icon artwork, recolored per UI: purple
    /// for the main UI, the original blue second, gray third.
    private var assetName: String {
        switch style {
        case .workslop: return "BrandBlue"
        case .nugget: return "BrandGray"
        case .modern: return "BrandPurple"
        }
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
    }
}

/// Drifting Apple-logo backdrop, mirroring the desktop v4 UI's Sky
/// background: faint "apple.logo" watermarks slowly floating and
/// turning behind the content. Static when Reduce Motion is on.
struct AppleDriftBackground: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
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
        GeometryReader { geo in
            ZStack {
                if style.showsDrift {
                    // Near-white tinted backdrop, like the reference
                    // UI: the UI color as a whisper, not a wash.
                    Color(UIColor.systemBackground)
                    LinearGradient(
                        colors: [tint.opacity(0.10), tint.opacity(0.03)],
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
                        .foregroundStyle(Color.white.opacity(0.16))
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
