import SwiftUI

struct ContentView: View {
    @StateObject private var selection = SelectionStore()
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .accessibilityIdentifier("tab-home")

            LiquidGlassView()
                .tabItem { Label("Liquid Glass", systemImage: "square.stack.3d.up.fill") }
                .accessibilityIdentifier("tab-liquid-glass")

            TweaksView()
                .tabItem { Label("Tweaks", systemImage: "slider.horizontal.3") }
                .accessibilityIdentifier("tab-tweaks")

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .accessibilityIdentifier("tab-settings")
        }
        .tint(style.tint)
        .environmentObject(selection)
    }
}

struct HomeView: View {
    @EnvironmentObject private var selection: SelectionStore
    @State private var pairingImported = PairingStore.isImported
    @State private var vpnDetected = DeviceStatus.vpnTunnelActive()

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        BrandTile()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WorkSlop")
                                .font(.title2.weight(.bold))
                            Text("v14.0 • Mobile (New)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // This device + VPN tunnel state. The on-device
                    // route runs over a loopback WireGuard tunnel, so
                    // the Home screen says plainly whether one is up.
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Device", systemImage: "iphone")
                                .font(.headline)
                            LabeledContent("Model", value: DeviceStatus.model)
                            LabeledContent("iOS", value: "\(DeviceInfo.iosVersion.major).\(DeviceInfo.iosVersion.minor)")
                            HStack {
                                Text("VPN tunnel")
                                Spacer()
                                StatusChip(
                                    text: vpnDetected ? "Detected" : "Not detected",
                                    warn: !vpnDetected)
                            }
                            Text("On-device tweaks run through this device over a loopback WireGuard tunnel. Any active VPN tunnel counts here — the app cannot see which VPN app owns it.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button("Refresh") {
                                vpnDetected = DeviceStatus.vpnTunnelActive()
                            }
                            .font(.footnote)
                            .accessibilityIdentifier("refresh-device")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Pairing status: the pairing record is the .plist
                    // from idevicepair, imported once in Settings.
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Pairing file", systemImage: "key.fill")
                                .font(.headline)
                            Text(pairingImported
                                 ? "A pairing file (.plist from idevicepair) is imported."
                                 : "No pairing file yet. Import the .plist from idevicepair pair in Settings.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            StatusChip(
                                text: pairingImported ? "Imported" : "Not imported",
                                warn: !pairingImported)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Staged selections summary. Staging is selection
                    // only — the Apply buttons on the tweak tabs say
                    // plainly that the engine is not connected yet.
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Staged tweaks", systemImage: "checklist")
                                .font(.headline)
                            Text(selection.staged.isEmpty
                                 ? "No tweaks selected. Flip toggles on the Liquid Glass / Tweaks tabs — only tweaks this iOS cannot run are locked."
                                 : "\(selection.staged.count) tweak(s) selected. The Apply buttons live on the Liquid Glass and Tweaks tabs.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Liquid Glass (Terbaru) menu, as on the desktop Home.
                    NavigationLink {
                        LiquidGlassView()
                    } label: {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Liquid Glass (Latest)", systemImage: "square.stack.3d.up.fill")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("The latest route: a payload read from the iOS 26.6.1 firmware, sent by full backup → modify → restore. The on-screen effect is decided by an on-device test.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .accessibilityIdentifier("home-lg-latest")

                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Beta testers")
                                .font(.headline)
                            Text("Charlie • rfrz1d_ • Davy (@Davydavpn) • @uggtx")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                }
            }
            .navigationTitle("Home")
            .onAppear { pairingImported = PairingStore.isImported }
        }
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
                    LabeledContent("This device's iOS", value: "\(DeviceInfo.iosVersion.major).\(DeviceInfo.iosVersion.minor)")
                }
                Section("Appearance (3 UIs)") {
                    Picker("UI", selection: $uiStyleRaw) {
                        ForEach(UIStyle.allCases, id: \.rawValue) { style in
                            Text(style.displayName).tag(style.rawValue)
                        }
                    }
                    .accessibilityIdentifier("ui-style-picker")
                    Text("Switching re-themes the app right away (tint color, brand tile, corners).")
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
                allowedContentTypes: [.propertyList, .data]) { result in
                switch result {
                case .success(let url):
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
