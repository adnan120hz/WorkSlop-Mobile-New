import SwiftUI

/// First-launch introduction. Shown once (UserDefaults flag), then
/// reachable again from Settings. It states plainly what WorkSlop
/// Mobile supports on iOS and what it needs before anything is applied.
///
/// The support lines mirror the desktop support matrix: partial-restore
/// tweaks cover the desktop 16.0 to <27.0 support line; Liquid Glass keys
/// live on iOS 26+, the S8 (Latest) payload targets iOS 26.0+, and
/// iOS 27 follows the desktop's separate full-flow handling. On-device
/// sending stays behind the restore engine, which is not verified on
/// iOS 26.6.1 yet — the intro says so instead of promising it.
struct IntroView: View {
    @AppStorage("seenIntro") private var seenIntro = false
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        ZStack {
            AppleDriftBackground()
            VStack(spacing: 0) {
            TabView(selection: $page) {
                introPage(
                    icon: nil,
                    title: "WorkSlop",
                    lines: [
                        "On-device tweaks for this iPhone: Liquid Glass, Status Bar, Daemons, Apple Internal, SpringBoard, Custom Icons and Themes — picked from the bottom menus.",
                        "This device: \(DeviceStatus.modelOrDash) • iOS \(DeviceInfoEx.fullVersion)",
                    ])
                .tag(0)

                introPage(
                    icon: "checkmark.seal",
                    title: "Supported iOS",
                    lines: [
                        "Liquid Glass (regular set): iOS 26.0 and later.",
                        "Liquid Glass iOS 26.6.1 RC S8: iOS 26.6.x builds 23G82/23G83 only.",
                        "Status Bar classic options: iOS 26.x (iOS 27 keeps carrier text only).",
                        "Everything rides the desktop support line, gated per tweak on its page - a tweak is only locked when this iOS is outside its range. Most tweaks ride Partial restore (max iOS 26); the S8 set uses full backup (all data) on iOS 26.6.1. On iOS 27, features whose support reaches 27 ride Full backup \u{2192} modify \u{2192} restore; features limited to iOS 16.0\u{2013}<27.0 stay locked. Status Bar classic options are iOS 26.x; iOS 27 keeps carrier text only.",
                        "Devices below iOS 16.0 or above iOS 27 get a full-screen \"iOS version not supported\" notice instead of this app.",
                    ])
                .tag(1)

                introPage(
                    icon: "shield",
                    title: "Before you apply",
                    lines: [
                        "Import the pairing file (.plist from idevicepair) in Settings.",
                        "Applies are designed to run over a loopback VPN tunnel to this same phone.",
                        "The app cannot reboot your iPhone — after an apply you restart manually.",
                        "Cancel really stops: a cancelled restore never keeps running in the background.",
                        "Apply builds the real payload on this phone and runs it through the on-device restore engine.",
                    ])
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == 2 ? "Start" : "Continue") {
                if page == 2 {
                    seenIntro = true
                    dismiss()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .accessibilityIdentifier("intro-continue")
            }
        }
    }

    private func introPage(icon: String?, title: String, lines: [String]) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 52))
                        .foregroundStyle(.tint)
                        .padding(.top, 32)
                } else {
                    BrandTile(size: 84)
                        .padding(.top, 32)
                }
                Text(title)
                    .font(.title.weight(.bold))
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .cardSurface(style, glass: true)
                .padding(.horizontal, 20)
                Spacer(minLength: 24)
            }
        }
    }
}
