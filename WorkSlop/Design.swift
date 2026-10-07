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
        case .workslop: return "WorkSlop v4"
        case .nugget: return "Nugget"
        case .modern: return "Modern"
        }
    }

    var tint: Color {
        switch self {
        case .workslop: return Brand.blue
        case .nugget: return Color(red: 0.35, green: 0.30, blue: 0.92)
        case .modern: return Color(red: 0.10, green: 0.10, blue: 0.12)
        }
    }

    var tileFill: Color {
        switch self {
        case .workslop: return Brand.blue
        case .nugget: return Color(red: 0.35, green: 0.30, blue: 0.92)
        case .modern: return Color(red: 0.10, green: 0.10, blue: 0.12)
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
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    var body: some View {
        RoundedRectangle(cornerRadius: Brand.tileCorner * style.tileCornerScale * size / 54)
            .fill(style.tileFill)
            .frame(width: size, height: size)
            .overlay(
                Text("WS")
                    .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            )
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
