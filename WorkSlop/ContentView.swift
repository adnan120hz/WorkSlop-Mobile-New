import SwiftUI

struct ContentView: View {
    @StateObject private var selection = SelectionStore()
    @AppStorage("appIconChoice") private var appIconChoice = ""

    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: style.tabIcons.home) }
                .accessibilityIdentifier("tab-home")

            LiquidGlassView()
                .tabItem { Label("Liquid Glass", systemImage: style.tabIcons.lg) }
                .accessibilityIdentifier("tab-liquid-glass")

            StatusBarView()
                .tabItem { Label("Status Bar", systemImage: "antenna.radiowaves.left.and.right") }
                .accessibilityIdentifier("tab-status-bar")

            DaemonsView()
                .tabItem { Label("Daemons", systemImage: "gearshape.2") }
                .accessibilityIdentifier("tab-daemons")

            AppleInternalView()
                .tabItem { Label("Apple Internal", systemImage: "wrench.and.screwdriver") }
                .accessibilityIdentifier("tab-apple-internal")

            SpringBoardView()
                .tabItem { Label("SpringBoard", systemImage: "square.grid.2x2") }
                .accessibilityIdentifier("tab-springboard")

            CustomIconsView()
                .tabItem { Label("Custom Icons", systemImage: "app.badge") }
                .accessibilityIdentifier("tab-custom-icons")

            PosterBoardView()
                .tabItem { Label("Themes", systemImage: "photo.on.rectangle") }
                .accessibilityIdentifier("tab-posterboard")

            SettingsView()
                .tabItem { Label("Settings", systemImage: style.tabIcons.settings) }
                .accessibilityIdentifier("tab-settings")
        }
        .tint(style.tint)
        .onChange(of: uiStyleRaw) { _ in
            // The WorkSlop app icon follows the UI automatically:
            // purple for the main UI, blue second, gray third.
            if appIconChoice.isEmpty {
                UIApplication.shared.setAlternateIconName(style.iconColorName)
            }
        }
        .environmentObject(selection)
        .preferredColorScheme(style == .nugget ? .dark : nil)
    }
}

struct HomeView: View {
    @EnvironmentObject private var selection: SelectionStore
    @State private var pairingImported = PairingStore.isImported
    @State private var vpnDetected = DeviceStatus.vpnTunnelActive()
    @State private var engineStatus = "Engine not probed yet - tap Refresh device status."
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                switch style {
                case .nugget:
                    nuggetHome
                case .modern:
                    modernHome
                case .workslop:
                    workslopHome
                }
            }
            .navigationTitle("Home")
            .onAppear { pairingImported = PairingStore.isImported }
        }
    }

    // MARK: - Nugget layout: compact gray rows, no cards/drift

    private var nuggetHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    BrandTile(size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("WorkSlop").font(.headline)
                        Text("v14.0 • Mobile").font(.caption).foregroundStyle(.secondary)
                    }
                }
                VStack(spacing: 0) {
                    nuggetRow("iphone", "Device", "\(DeviceStatus.modelOrDash) • \(DeviceInfoEx.versionWithBuild)")
                    Divider()
                    nuggetRow("network", "VPN tunnel", vpnDetected ? "Detected" : "Not detected")
                    Divider()
                    nuggetRow("key.fill", "Pairing file", pairingImported ? "Imported" : "Not imported")
                    Divider()
                    nuggetRow("checklist", "Staged tweaks", "\(selection.staged.count) selected")
                }
                .padding(.horizontal, 12)
                .cardSurface(style, glass: true, radius: 22)
                Button("Refresh device status") {
                    vpnDetected = DeviceStatus.vpnTunnelActive()
                }
                .font(.footnote)
                menuLinks
                NavigationLink {
                    LiquidGlassView()
                } label: {
                    HStack {
                        Label("Liquid Glass (Latest)", systemImage: "square.stack.3d.up")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .cardSurface(style, glass: true, radius: 22)
                }
                .accessibilityIdentifier("home-lg-latest")
                Text("Beta testers: Charlie • rfrz1d_ • Davy (@Davydavpn) • @uggtx")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func nuggetRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 22)
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).font(.callout)
        }
        .padding(.vertical, 9)
    }

    // MARK: - Nugget Modern layout: centered header + tile grid

    private var modernHome: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    BrandTile(size: 84)
                    Text("WorkSlop").font(.title.weight(.bold))
                    Text("v14.0 • Mobile").font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink {
                    LiquidGlassView()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Liquid Glass (Latest)", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Full backup → modify → restore. Decided by an on-device test.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .cardSurface(style, glass: true)
                }
                .accessibilityIdentifier("home-lg-latest")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    modernTile("iphone", "Device",
                               "\(DeviceStatus.modelOrDash)\n\(DeviceInfoEx.versionWithBuild)")
                    modernTile("network", "VPN tunnel", vpnDetected ? "Detected" : "-")
                    modernTile("key.fill", "Pairing file", pairingImported ? "Imported" : "Not imported")
                    modernTile("checklist", "Staged", "\(selection.staged.count) selected")
                }
                menuLinks
                Button("Refresh device status") {
                    vpnDetected = DeviceStatus.vpnTunnelActive()
                }
                .font(.footnote)
                Text("Beta testers: Charlie • rfrz1d_ • Davy (@Davydavpn) • @uggtx")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func modernTile(_ icon: String, _ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
            Text(title).font(.subheadline.weight(.semibold))
            Text(value).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(14)
        .cardSurface(style, glass: true)
    }

    // MARK: - WorkSlop main layout (blue): tile grid, left header


    private var workslopHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    BrandTile(size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WorkSlop")
                            .font(.title3.weight(.bold))
                        Text("v14.0 \u{2022} Mobile")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    LiquidGlassView()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Liquid Glass (Latest)", systemImage: "square.stack.3d.up.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Full backup \u{2192} modify \u{2192} restore. Decided by an on-device test.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .cardSurface(style, glass: true)
                }
                .accessibilityIdentifier("home-lg-latest")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    mainTile("iphone", "Device",
                             "\(DeviceStatus.modelOrDash)\n\(DeviceInfoEx.versionWithBuild)")
                    mainTile("network", "VPN tunnel", vpnDetected ? "Detected" : "-")
                    mainTile("key.fill", "Pairing file", pairingImported ? "Imported" : "-")
                    mainTile("checklist", "Staged", "\(selection.staged.count) selected")
                }
                menuLinks
                Button("Refresh device status") {
                    refreshStatus()
                }
                .font(.footnote)
                Text(engineStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }


    /// Menu shortcuts that also live in the bottom tabs — visible
    /// right on Home, as requested.
    private var menuLinks: some View {
        VStack(spacing: 10) {
            homeMenuLink("app.badge", "Custom Icons", "Your own bookmark icons from image files") {
                CustomIconsView()
            }
            homeMenuLink("photo.on.rectangle", "Themes", "PosterBoard .tendies + Templates .batter") {
                PosterBoardView()
            }
        }
    }

    private func homeMenuLink<Destination: View>(
        _ icon: String, _ title: String, _ subtitle: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .cardSurface(style, glass: true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    /// Refresh device facts and probe the pairing-file engine route:
    /// tunnel address -> lockdownd over the loopback tunnel.
    private func refreshStatus() {
        vpnDetected = DeviceStatus.vpnTunnelActive()
        pairingImported = PairingStore.isImported
        engineStatus = "Probing lockdownd..."
        LockdownProbe.probe { result in
            DispatchQueue.main.async { engineStatus = result.summary }
        }
    }

    private func mainTile(_ icon: String, _ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
            Text(title).font(.subheadline.weight(.semibold))
            Text(value).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(14)
        .cardSurface(style, glass: true)
    }
}

struct SettingsView: View {
    @State private var importing = false
    @State private var pairingNote: String?
    @State private var showTunnelInfo = false
    @State private var pairingImported = PairingStore.isImported
    /// The desktop ships three UIs; the picker exists here too and
    /// re-themes the app (tint, brand tile, corners).
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @AppStorage("appIconChoice") private var appIconChoice = ""

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                Section("App") {
                    LabeledContent("Version", value: "14.0")
                    LabeledContent("Repo", value: "WorkSlop-Mobile-New")
                    LabeledContent("This device's iOS", value: DeviceInfoEx.fullVersion)
                }
                Section("Appearance (3 UIs)") {
                    Picker("UI", selection: $uiStyleRaw) {
                        ForEach(UIStyle.allCases, id: \.rawValue) { style in
                            Text(style.displayName).tag(style.rawValue)
                        }
                    }
                    .accessibilityIdentifier("ui-style-picker")
                    Text("Three different UIs: purple grid (main, Nugget Modern), blue tile grid (WorkSlop), dark gray compact rows (Nugget). Layout, colors and icons all change.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Picker(selection: $appIconChoice) {
                        Text("Automatic (follows UI)").tag("")
                        Text("Purple (main)").tag("IconPurple")
                        Text("Blue").tag("IconBlue")
                        Text("Gray").tag("IconGray")
                    } label: {
                        Label("WorkSlop app icon", systemImage: "app.badge")
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("app-icon-picker")
                    .onChange(of: appIconChoice) { choice in
                        let style = UIStyle(rawValue: uiStyleRaw) ?? .modern
                        UIApplication.shared.setAlternateIconName(
                            choice.isEmpty ? style.iconColorName : choice)
                    }
                    Text("The app icon follows the UI by itself - purple for the main UI, blue second, gray third - unless you pin one here. The in-app brand tile follows the same rule.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Safety") {
                    Text("Cancel here only unstages - nothing is in flight yet. A running restore has no true cancel on desktop either; it offers Abort or Resume if the device reconnects. This app never keeps working in the background after a stop.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Verify before restore. An apply checks the backup first; if any check fails, the whole apply is cancelled before anything is sent.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Restart is manual. This app cannot reboot your iPhone. After an apply you will be told: restart manually now.")
                    Text("Find My must be OFF before an apply and back ON afterwards - same rule as the desktop.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Rollback: if Liquid Glass (Latest) was applied, removing it deletes exactly its four keys from a fresh capture of this phone - nothing else is touched. The rollback rides the same engine and the same restart rule.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Emergency stop: if you must stop an apply mid-way, turn off WireGuard first, then force restart — press Volume Up, Volume Down, then hold the Side button until the Apple logo appears.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Section("Credits") {
                    LabeledContent("Developer", value: "Adnan.120hz")
                    LabeledContent("Beta testers", value: "Charlie • rfrz1d_ • Davy (@Davydavpn) • @uggtx")
                    Text("WorkSlop Mobile is its own app — not a port of the desktop build. Tweak payloads follow the key audit of the iOS 26.6.1 firmware.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Import pairing file (.plist)") { importing = true }
                        .accessibilityIdentifier("import-pairing")
                    LabeledContent("Status", value: pairingImported ? "Imported" : "Not imported")
                    Button {
                        showTunnelInfo = true
                    } label: {
                        Label("What is the VPN tunnel?", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("tunnel-info")
                    if pairingImported {
                        Button("Delete pairing file", role: .destructive) {
                            do {
                                try FileManager.default.removeItem(at: PairingStore.fileURL)
                                pairingImported = PairingStore.isImported
                                pairingNote = "Pairing file deleted from the app container."
                            } catch {
                                pairingNote = "Could not delete the pairing file: \(error.localizedDescription)"
                            }
                        }
                    }
                    Text("The pairing file comes from idevicepair pair (a .plist). It is stored in the app container and used for the local lockdown session by the backup/restore engine.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let pairingNote {
                        Text(pairingNote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Pairing file")
                }
            .scrollContentBackground(.hidden)
            .modifier(ThemedListStyle(style: style))
            .sheet(isPresented: $showTunnelInfo) { TunnelInfoView() }
            .modifier(ThemedRows(style: style))
            }
            }
            .navigationTitle("Settings")
            .onAppear { pairingImported = PairingStore.isImported }
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: [.propertyList]) { result in
                switch result {
                case .success(let url):
                    // Only .plist is ever accepted; other formats stay
                    // greyed out in the picker and are rejected here too.
                    guard url.pathExtension.lowercased() == "plist" else {
                        pairingNote = "Only a .plist pairing file is accepted — nothing was saved."
                        return
                    }
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    guard let data = try? Data(contentsOf: url) else {
                        pairingNote = "The file could not be read — nothing was saved."
                        return
                    }
                    guard PairingStore.validate(data) else {
                        pairingNote = "That file is not a valid idevicepair pairing record — nothing was saved."
                        return
                    }
                    do {
                        try PairingStore.save(data)
                        pairingImported = PairingStore.isImported
                        pairingNote = "Pairing file saved."
                    } catch {
                        pairingNote = "Could not save the pairing file: \(error.localizedDescription)"
                    }
                case .failure:
                    pairingNote = "Import cancelled."
                }
            }
        }
    }
}

/// The (i) explainer for the pairing section: what the loopback VPN
/// tunnel is (and is not), and App Store apps that can open one.
struct TunnelInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("What the tunnel is") {
                    Text("WorkSlop runs on the same iPhone it tweaks. To deliver a payload it must talk to this phone's own lockdownd service, and iOS does not let an app open that connection directly - the traffic has to ride a local VPN tunnel (a utun interface) back into the phone itself.")
                    Text("This is NOT an internet VPN: no traffic leaves your iPhone, nothing is routed through a server, and your browsing is untouched. The tunnel is only a loopback bridge to this device, and your pairing file is what authenticates the session.")
                }
                Section("Apps that can open the tunnel") {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("WireGuard").font(.body.weight(.semibold))
                        Text("The official WireGuard app (free). With a loopback configuration it opens the tunnel WorkSlop detects - the standard choice.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("StikDebug").font(.body.weight(.semibold))
                        Text("Free. Creates its own local VPN profile for the same kind of loopback tunnel.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Shadowrocket / Stash").font(.body.weight(.semibold))
                        Text("Paid alternatives that can also hold a tunnel open, but they are proxy apps - more than this needs.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("WorkSlop only detects the tunnel; it never sees or routes your internet traffic.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("VPN tunnel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
