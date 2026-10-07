import SwiftUI

struct ContentView: View {
    @StateObject private var selection = SelectionStore()
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
                .tabItem { Label("PosterBoard", systemImage: "photo.on.rectangle") }
                .accessibilityIdentifier("tab-posterboard")

            SettingsView()
                .tabItem { Label("Settings", systemImage: style.tabIcons.settings) }
                .accessibilityIdentifier("tab-settings")
        }
        .tint(style.tint)
        .environmentObject(selection)
        .preferredColorScheme(style == .nugget ? .dark : nil)
    }
}

struct HomeView: View {
    @AppStorage("glassUI") private var glassUI = true
    @EnvironmentObject private var selection: SelectionStore
    @State private var pairingImported = PairingStore.isImported
    @State private var vpnDetected = DeviceStatus.vpnTunnelActive()
    @State private var engineStatus = "Engine not probed yet - tap Refresh device status."
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
                    nuggetRow("iphone", "Device", "\(DeviceStatus.model) • iOS \(DeviceInfo.iosVersion.major).\(DeviceInfo.iosVersion.minor)")
                    Divider()
                    nuggetRow("network", "VPN tunnel", vpnDetected ? "Detected" : "Not detected")
                    Divider()
                    nuggetRow("key.fill", "Pairing file", pairingImported ? "Imported" : "Not imported")
                    Divider()
                    nuggetRow("checklist", "Staged tweaks", "\(selection.staged.count) selected")
                }
                .padding(.horizontal, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    BrandTile(size: 68)
                    Text("WorkSlop").font(.title2.weight(.bold))
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
                    .background(Color.white.opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .accessibilityIdentifier("home-lg-latest")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    modernTile("iphone", "Device",
                               "\(DeviceStatus.modelOrDash)\n\(DeviceInfoEx.versionWithBuild)")
                    modernTile("network", "VPN tunnel", vpnDetected ? "Detected" : "-")
                    modernTile("key.fill", "Pairing file", pairingImported ? "Imported" : "Not imported")
                    modernTile("checklist", "Staged", "\(selection.staged.count) selected")
                }
                appearanceChoice
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
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - WorkSlop main layout (blue): tile grid, left header


    /// iOS 26/27 only: the "Liquid Glass UI" vs "No Liquid Glass"
    /// app-appearance choice that sits on Home. Picking "No Liquid
    /// Glass" flattens the app and blocks the style choice below it.
    @ViewBuilder
    private var appearanceChoice: some View {
        if DeviceInfo.iosVersion >= (26, 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("App appearance (iOS 26)")
                    .font(.subheadline.weight(.semibold))
                Picker("App appearance", selection: $glassUI) {
                    Text("Liquid Glass UI").tag(true)
                    Text("No Liquid Glass").tag(false)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("appearance-picker")
                if !glassUI {
                    Text("Flat look on: the glass backgrounds are off and the UI style choice in Settings is blocked.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

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
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier("home-lg-latest")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    mainTile("iphone", "Device",
                             "\(DeviceStatus.modelOrDash)\n\(DeviceInfoEx.versionWithBuild)")
                    mainTile("network", "VPN tunnel", vpnDetected ? "Detected" : "-")
                    mainTile("key.fill", "Pairing file", pairingImported ? "Imported" : "-")
                    mainTile("checklist", "Staged", "\(selection.staged.count) selected")
                }
                appearanceChoice
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
            homeMenuLink("app.badge", "Custom Icons", "Bookmark icons from Cowabunga or your own PNG") {
                CustomIconsView()
            }
            homeMenuLink("photo.on.rectangle", "PosterBoard", "Import .tendies first - no direct apply here") {
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
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SettingsView: View {
    @State private var importing = false
    @State private var pairingNote: String?
    @State private var pairingImported = PairingStore.isImported
    /// The desktop ships three UIs; the picker exists here too and
    /// re-themes the app (tint, brand tile, corners).
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

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
                    Text("Three different UIs: blue tile grid (main), dark gray compact rows (Nugget), purple grid (Nugget Modern). Layout, colors and icons all change.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Safety") {
                    Text("Cancel means stopped. If an apply is running and you cancel, the restore session is terminated — it never keeps working in the background.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Verify before restore. An apply checks the backup first; if any check fails, the whole apply is cancelled before anything is sent.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Restart is manual. This app cannot reboot your iPhone. After an apply you will be told: restart manually now.")
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
                Section("Pairing file") {
                    Button("Import pairing file (.plist)") { importing = true }
                        .accessibilityIdentifier("import-pairing")
                    LabeledContent("Status", value: pairingImported ? "Imported" : "Not imported")
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
                }
            .scrollContentBackground(.hidden)
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
