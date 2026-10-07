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

                    // Pairing status: the pairing record is the .plist
                    // from idevicepair, imported once in Settings.
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Pairing file", systemImage: "iphone")
                                .font(.headline)
                            Text(pairingImported
                                 ? "File pairing (.plist dari idevicepair) sudah terimpor."
                                 : "Belum ada file pairing. Impor .plist hasil idevicepair pair di Settings.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            StatusChip(
                                text: pairingImported ? "Terimpor" : "Belum terimpor",
                                warn: !pairingImported)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Staged selections summary. Staging is selection
                    // only — the Apply buttons on the tweak tabs say
                    // plainly that the engine is not connected yet.
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Pilihan ter-stage", systemImage: "checklist")
                                .font(.headline)
                            Text(selection.staged.isEmpty
                                 ? "Belum ada tweak yang dipilih. Aktifkan toggle di tab Liquid Glass / Tweaks — yang terkunci hanya yang iOS-nya tidak mendukung."
                                 : "\(selection.staged.count) tweak dipilih. Tombol Apply ada di tab Liquid Glass dan Tweaks.")
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
                                Label("Liquid Glass (Terbaru)", systemImage: "square.stack.3d.up.fill")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Cara terbaru: payload terbaca firmware iOS 26.6.1, dikirim lewat full backup → modify → restore. Efek layar diputus oleh uji device.")
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
                            Text("Beta tester")
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
                    LabeledContent("Versi", value: "14.0")
                    LabeledContent("Repo", value: "WorkSlop-Mobile-New")
                    LabeledContent("iOS device ini", value: "\(DeviceInfo.iosVersion.major).\(DeviceInfo.iosVersion.minor)")
                }
                Section("Tampilan (3 UI)") {
                    Picker("UI", selection: $uiStyleRaw) {
                        ForEach(UIStyle.allCases, id: \.rawValue) { style in
                            Text(style.displayName).tag(style.rawValue)
                        }
                    }
                    .accessibilityIdentifier("ui-style-picker")
                    Text("Pilihan langsung mengubah tema app (warna tint, tile brand, sudut).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Pairing file") {
                    Button("Impor file pairing (.plist)") { importing = true }
                        .accessibilityIdentifier("import-pairing")
                    LabeledContent("Status", value: pairingImported ? "Terimpor" : "Belum terimpor")
                    if pairingImported {
                        Button("Hapus file pairing", role: .destructive) {
                            do {
                                try FileManager.default.removeItem(at: PairingStore.fileURL)
                                pairingImported = PairingStore.isImported
                                pairingNote = "File pairing dihapus dari container app."
                            } catch {
                                pairingNote = "Gagal menghapus file pairing: \(error.localizedDescription)"
                            }
                        }
                    }
                    Text("File pairing didapat dari idevicepair pair (berkas .plist). File disimpan di container app dan dipakai untuk sesi lockdown lokal oleh mesin backup/restore.")
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
                        pairingNote = "File tidak bisa dibaca — tidak disimpan."
                        return
                    }
                    guard PairingStore.validate(data) else {
                        pairingNote = "File itu bukan pairing record idevicepair yang valid — tidak disimpan."
                        return
                    }
                    do {
                        try PairingStore.save(data)
                        pairingImported = PairingStore.isImported
                        pairingNote = "File pairing tersimpan."
                    } catch {
                        pairingNote = "Gagal menyimpan file pairing: \(error.localizedDescription)"
                    }
                case .failure:
                    pairingNote = "Impor dibatalkan."
                }
            }
        }
    }
}
