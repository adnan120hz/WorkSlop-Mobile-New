import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Status Bar (desktop page parity, staged values)

/// All desktop Status Bar page controls, staged on-device. The values
/// ride the 0xF68 `statusBarOverrides` struct (field layout
/// firmware-verified on iOS 26.6.1). The struct itself is assembled
/// from the device's captured base during a restore session — never
/// fabricated in the app — so this page stages values, honestly.
struct StatusBarView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @AppStorage("sb-on") private var masterOn = false
    @AppStorage("sb-fullsignal") private var fullSignal = false
    @AppStorage("sb-silly") private var sillyMode = false
    @AppStorage("sb-time") private var timeText = ""
    @AppStorage("sb-date") private var dateText = ""
    @AppStorage("sb-crumb") private var crumbText = ""
    @AppStorage("sb-battdetail") private var batteryDetail = ""
    @AppStorage("sb-carrier") private var carrierText = ""
    @AppStorage("sb-badge") private var badgeText = ""
    @AppStorage("sb-carrier2") private var carrier2Text = ""
    @AppStorage("sb-badge2") private var badge2Text = ""
    @AppStorage("sb-bars") private var signalBars = 4
    @AppStorage("sb-bars2") private var signalBars2 = 4
    @AppStorage("sb-wifibars") private var wifiBars = 3
    @AppStorage("sb-battcap") private var batteryCapacity = 100
    @AppStorage("sb-nettype") private var netType = 0
    @AppStorage("sb-nettype2") private var netType2 = 0
    @AppStorage("sb-numcell") private var numericCell = false
    @AppStorage("sb-numwifi") private var numericWifi = false
    @AppStorage("sb-hidden-items") private var hiddenItemsRaw = ""

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    /// Desktop-mapped status bar items that can be hidden
    /// (itemIsEnabled indexes from the desktop page).
    private static let hideableItems: [(idx: Int, name: String)] = [
        (2, "Focus Mode icon"), (3, "Airplane Mode icon"),
        (6, "Cellular Service icon"), (9, "Wi-Fi icon"),
        (12, "Battery icon"), (16, "Bluetooth icon"),
        (18, "Alarm icon"), (21, "Location icon"),
        (22, "Rotation Lock icon"), (24, "AirPlay icon"),
        (26, "CarPlay icon"), (29, "VPN icon"),
        (40, "Liquid Detection icon"), (41, "Voice Control icon"),
    ]

    private var hiddenItems: Set<Int> {
        Set(hiddenItemsRaw.split(separator: ",").compactMap { Int($0) })
    }

    private func toggleItem(_ idx: Int, _ on: Bool) {
        var items = hiddenItems
        if on { items.insert(idx) } else { items.remove(idx) }
        hiddenItemsRaw = items.sorted().map(String.init).joined(separator: ",")
    }

    private var feature: Feature {
        FeatureCatalog.features(in: "Status Bar")[0]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        LockBanner()
                    }
                    Section {
                        FeatureRow(feature: feature)
                        Toggle("Enable Status Bar Modifications", isOn: $masterOn)
                        Toggle("Full Signal Bars (No SIM Visual)", isOn: $fullSignal)
                            .disabled(!ActivationGate.unlocked)
                        Toggle("Silly Mode", isOn: $sillyMode)
                            .disabled(!ActivationGate.unlocked)
                            .accessibilityIdentifier("sb-enable")
                    } header: {
                        Text("Master")
                    } footer: {
                        Text("Target: Library/SpringBoard/statusBarOverrides — a fixed 3,944-byte struct, not a plist (firmware-audited on iOS 26.6.1). The full-bars look without a SIM is visual only; it does not restore cellular service.")
                    }
                    Section("Text overrides") {
                        TextField("Status Bar Time Text", text: $timeText)
                        TextField("Date Text", text: $dateText)
                        TextField("Breadcrumb Text", text: $crumbText)
                        TextField("Battery Detail Text", text: $batteryDetail)
                        TextField("Carrier Text", text: $carrierText)
                        TextField("Service Badge Text", text: $badgeText)
                        TextField("Secondary Carrier Name", text: $carrier2Text)
                        TextField("Secondary Service Badge", text: $badge2Text)
                    }
                    Section("Numbers") {
                        Stepper("Signal Strength: \(signalBars)", value: $signalBars, in: 0...5)
                        Stepper("Secondary Signal Bars: \(signalBars2)", value: $signalBars2, in: 0...5)
                        Stepper("Wi-Fi Signal Strength: \(wifiBars)", value: $wifiBars, in: 0...5)
                        Stepper("Battery Icon Capacity: \(batteryCapacity)%", value: $batteryCapacity, in: 0...100)
                        Stepper("Data Network Type: \(netType)", value: $netType, in: 0...30)
                        Stepper("Secondary Data Network Type: \(netType2)", value: $netType2, in: 0...30)
                        Toggle("Show Numeric Cellular Strength", isOn: $numericCell)
                        Toggle("Show Numeric Wi-Fi Strength", isOn: $numericWifi)
                    }
                    Section("Hide icons") {
                        ForEach(Self.hideableItems, id: \.idx) { item in
                            Toggle("Hide \(item.name)", isOn: Binding(
                                get: { hiddenItems.contains(item.idx) },
                                set: { toggleItem(item.idx, $0) }))
                        }
                    }
                    Section {
                        Text("Values stage here exactly like the desktop page. The struct is built from the device's captured base during the restore session.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Section {
                        ApplySection()
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            }
            .navigationTitle("Status Bar")
        }
    }
}

// MARK: - Daemons

struct DaemonsView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        LockBanner()
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "Daemons")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Daemons")
                    } footer: {
                        Text("Daemon toggles stage the same disabled-daemons list the desktop manages; what lands on the device depends on the restore engine, which is not verified on iOS 26.6.1 yet.")
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "Recommended")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Recommended set")
                    } footer: {
                        Text("The desktop one-tap Recommended analytics set, as individual switches.")
                    }
                    Section {
                        ApplySection()
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            }
            .navigationTitle("Daemons")
        }
    }
}

// MARK: - Apple Internal

struct AppleInternalView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        LockBanner()
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "Internal Options")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Apple Internal")
                    } footer: {
                        Text("Internal debug switches from Apple's own preference domains. Only keys verified in the iOS firmware are listed.")
                    }
                    Section {
                        ApplySection()
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            }
            .navigationTitle("Apple Internal")
        }
    }
}

// MARK: - Custom Icons

/// Custom icon for one app: image + bundle id + display name, staged
/// like the desktop Icon Themes flow. The staged entry rides the
/// parameterized WebClip write in PayloadSpec.swift.
struct CustomIconEntry: Identifiable, Codable {
    var id = UUID()
    var bundleID: String = ""
    var appName: String = ""
    var imageData: Data? = nil
}

enum CustomIconStore {
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("custom-icons.json")
    }

    static func load() -> [CustomIconEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([CustomIconEntry].self, from: data)
        else { return [] }
        return entries
    }

    static func save(_ entries: [CustomIconEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

struct CustomIconsView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @State private var entries: [CustomIconEntry] = CustomIconStore.load()
    @State private var picked: PhotosPickerItem?
    @State private var editingIndex: Int?

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        ForEach(entries.indices, id: \.self) { i in
                            HStack(spacing: 12) {
                                if let data = entries[i].imageData,
                                   let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color.secondary.opacity(0.25))
                                        .frame(width: 44, height: 44)
                                        .overlay(Image(systemName: "app").foregroundStyle(.secondary))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entries[i].appName.isEmpty ? "Unnamed app" : entries[i].appName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(entries[i].bundleID.isEmpty ? "Bundle ID not set" : entries[i].bundleID)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Edit") { editingIndex = i }
                                    .font(.footnote)
                            }
                        }
                        .onDelete { offsets in
                            entries.remove(atOffsets: offsets)
                            CustomIconStore.save(entries)
                        }
                        Button("Add app icon") {
                            entries.append(CustomIconEntry())
                            CustomIconStore.save(entries)
                            editingIndex = entries.count - 1
                        }
                        .accessibilityIdentifier("icons-add")
                    } header: {
                        Text("Your icons")
                    } footer: {
                        Text("Pick an image, fill the app name and its bundle ID (for example com.apple.mobilesafari). Staged icons are written as Home Screen web clips by the same restore payload as the desktop icon themes.")
                    }
                    Section("Icon packs") {
                        Text("Manual only: download icon packs anywhere you like, then add the images below one by one - image (JPEG / PNG / RAW), app name and bundle ID are all required.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .cardedRow(style, glass: true)
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "Custom Icons")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Delivery")
                    } footer: {
                        Text("With this on and at least one complete icon below, the staging payload built on disk gains one Cowabunga-style .webclip folder per app (Info.plist + icon.png). Nothing is on the Home Screen until the restore engine delivers it.")
                    }
                    Section {
                        ApplySection()
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            }
            .navigationTitle("Custom Icons")
            .sheet(item: Binding(
                get: { editingIndex.map { IndexBox(value: $0) } },
                set: { editingIndex = $0?.value })) { box in
                iconEditor(box.value)
            }
        }
    }

    private struct IndexBox: Identifiable { let value: Int; var id: Int { value } }

    @ViewBuilder
    private func iconEditor(_ i: Int) -> some View {
        if entries.indices.contains(i) {
            NavigationStack {
                Form {
                    Section("App") {
                        TextField("App name", text: $entries[i].appName)
                        TextField("Bundle ID", text: $entries[i].bundleID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Section("Icon image") {
                        if let data = entries[i].imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        PhotosPicker(selection: $picked, matching: .images) {
                            Label("Import image (JPEG / PNG / RAW)", systemImage: "photo")
                        }
                        Text("App name and bundle ID are required before this icon can be staged.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Icon")
                .toolbar {
                    Button("Done") {
                        CustomIconStore.save(entries)
                        editingIndex = nil
                    }
                }
                .onChange(of: picked) { item in
                    Task {
                        if let raw = try? await item?.loadTransferable(type: Data.self),
                           let image = UIImage(data: raw),
                           let png = image.pngData() {
                            entries[i].imageData = png
                            CustomIconStore.save(entries)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - PosterBoard

/// Import-first, like the desktop page: the user brings .tendies (or
/// .batter template) files, and only then do the PosterBoard modes
/// have anything to deliver. There is deliberately NO Apply button on
/// this page - imported files join the staged set and are delivered
/// by the engine from the Apply sections on the tweak pages.
struct PosterBoardView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @State private var importing = false
    @State private var note: String?
    @State private var files: [String] = TendiesStore.list(kind: "Tendies")
    @State private var templateFiles: [String] = TendiesStore.list(kind: "Templates")
    /// Which table the single importer serves ("Tendies"/"Templates").
    /// One importer only: two .fileImporter modifiers on one view
    /// conflict and the first never presents.
    @State private var importKind = "Tendies"

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        LockBanner()
                    }
                    Section {
                        Button("Import PosterBoard file (.tendies)") { importKind = "Tendies"; importing = true }
                            .accessibilityIdentifier("pb-import")
                            .cardedRow(style, glass: true)
                        if files.isEmpty {
                            Text("Nothing imported. PosterBoard delivers nothing until at least one .tendies is here.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .cardedRow(style, glass: true)
                        } else {
                            ForEach(files, id: \.self) { name in
                                Label(name, systemImage: "doc")
                                    .font(.footnote)
                            }
                            .onDelete { offsets in
                                TendiesStore.delete(at: offsets, from: files, kind: "Tendies")
                                files = TendiesStore.list(kind: "Tendies")
                            }
                        }
                        if let note {
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text("Descriptors ride a plain partial restore on desktop - no backup runs for this mode. Up to 5 files ride one apply (desktop cap).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .cardedRow(style, glass: true)
                    } header: {
                        Text("PosterBoard (.tendies)")
                    }
                    Section {
                        Button("Import Template file (.batter)") { importKind = "Templates"; importing = true }
                            .accessibilityIdentifier("themes-template-import")
                            .cardedRow(style, glass: true)
                        if templateFiles.isEmpty {
                            Text("Nothing imported. Templates install and manage delivered PosterBoard content the desktop way.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .cardedRow(style, glass: true)
                        } else {
                            ForEach(templateFiles, id: \.self) { name in
                                Label(name, systemImage: "doc")
                                    .font(.footnote)
                            }
                            .onDelete { offsets in
                                TendiesStore.delete(at: offsets, from: templateFiles, kind: "Templates")
                                templateFiles = TendiesStore.list(kind: "Templates")
                            }
                        }
                        Text("Different job from .tendies: template packages manage delivered PosterBoard content. (The database/Configurations side exists on desktop and is not offered on mobile.)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .cardedRow(style, glass: true)
                    } header: {
                        Text("Templates (.batter)")
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "PosterBoard")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Delivery modes")
                    } footer: {
                        Text("Both tables deliver by partial restore, like the desktop Descriptors mode. Nothing is delivered from this page; files join the staged set for the engine, when it runs.")
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            }
            .navigationTitle("Themes")
            .fileImporter(isPresented: $importing,
                          allowedContentTypes: [UTType(filenameExtension: importKind == "Tendies" ? "tendies" : "batter") ?? .data],
                          allowsMultipleSelection: true) { result in
                let kind = importKind
                let ext = kind == "Tendies" ? "tendies" : "batter"
                switch result {
                case .success(let urls):
                    var imported = 0
                    for url in urls {
                        guard url.pathExtension.lowercased() == ext else { continue }
                        let scoped = url.startAccessingSecurityScopedResource()
                        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        if TendiesStore.save(url: url, kind: kind) { imported += 1 }
                    }
                    files = TendiesStore.list(kind: "Tendies")
                    templateFiles = TendiesStore.list(kind: "Templates")
                    note = imported > 0
                        ? "Imported \(imported) .\(ext) file(s) into \(kind). Staged for the next engine apply."
                        : "Nothing imported - this table takes .\(ext) only."
                case .failure:
                    note = "Import cancelled."
                }
            }
        }
    }
}

// MARK: - Tendies store (PosterBoard imports)

enum TendiesStore {
    static func dir(kind: String) -> URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(kind, isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    static func list(kind: String) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: dir(kind: kind).path))?.sorted() ?? []
    }

    static func save(url: URL, kind: String) -> Bool {
        guard list(kind: kind).count < 5 else { return false }
        let dest = dir(kind: kind).appendingPathComponent(url.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
            return true
        } catch {
            return false
        }
    }

    static func delete(at offsets: IndexSet, from files: [String], kind: String) {
        for i in offsets {
            try? FileManager.default.removeItem(at: dir(kind: kind).appendingPathComponent(files[i]))
        }
    }
}

// MARK: - SpringBoard tweaks

struct SpringBoardView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        LockBanner()
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "SpringBoard")) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    Section {
                        ApplySection()
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            }
            .navigationTitle("SpringBoard")
        }
    }
}

/// Shown at the top of tweak lists while the pairing-file + VPN
/// gate is closed (toggles stay unusable until both are in place).
struct LockBanner: View {
    var body: some View {
        if !ActivationGate.unlocked {
            Text(ActivationGate.message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Apply + Cancel section (used on every page)

/// The Apply menu: what Apply does, the Apply button, and the Cancel
/// button that undoes the staging. Text mirrors the desktop safety
/// language and the phone's one hard limit: the app cannot reboot the
/// iPhone, so after a real apply the user restarts manually.
struct ApplySection: View {
    @EnvironmentObject private var selection: SelectionStore
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }
    @State private var built: BuiltPayload?
    @State private var showSheet = false
    @State private var confirmCancel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apply builds the real payload from your staged tweaks on this phone. Delivery to the system runs over the loopback VPN tunnel with your pairing file - and only once the on-device restore engine passes its checks; if any check fails, nothing is sent. Turn Find My OFF before an apply, ON again after - same as desktop.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                built = PayloadBuilder.build(staged: selection.staged)
                showSheet = true
            } label: {
                Text("Apply (\(selection.staged.count) tweak)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selection.staged.isEmpty)
            .accessibilityIdentifier("apply-button")
            Button(role: .destructive) {
                confirmCancel = true
            } label: {
                Text("Cancel (clear staged)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(selection.staged.isEmpty)
            .accessibilityIdentifier("cancel-button")
            Text("Cancel here unstages everything; nothing is in flight yet. A running restore has no true cancel - on desktop it offers Abort or Resume if the device reconnects; a hard stop is: turn off the VPN, then force-restart (Volume Up, Volume Down, hold Side button). After a successful apply you restart manually — this app cannot reboot your iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .confirmationDialog("Clear all staged tweaks?", isPresented: $confirmCancel) {
            Button("Clear staged", role: .destructive) {
                selection.clear()
            }
            Button("Keep", role: .cancel) {}
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                List {
                    Section("Payload built from your selection") {
                        if let built, !built.files.isEmpty {
                            ForEach(built.files) { file in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(file.restorePath)
                                        .font(.system(.footnote, design: .monospaced))
                                    Text("\(file.domain) — \(file.keys.count) key(s): \(file.keys.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("No fixed payload could be built from this selection.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let built, !built.warnings.isEmpty {
                        Section("Not staged") {
                            ForEach(built.warnings, id: \.self) { warning in
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Engine checks (parity with the desktop apply)") {
                        Label("Find My OFF (you check - the app cannot see it)", systemImage: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Label("Protective backup gate: desktop runs it only in the iOS 27 flow - skipped on iOS 26", systemImage: "checkmark.shield")
                            .foregroundStyle(.secondary)
                        Label("Delivery status: prepared only - staged, not delivered", systemImage: "tray")
                            .foregroundStyle(.secondary)
                        Label("Pairing file imported", systemImage: PairingStore.isImported ? "checkmark.circle" : "xmark.circle")
                            .foregroundStyle(PairingStore.isImported ? Color.green : Color.red)
                        Label("VPN tunnel on this device", systemImage: DeviceStatus.vpnTunnelActive() ? "checkmark.circle" : "xmark.circle")
                            .foregroundStyle(DeviceStatus.vpnTunnelActive() ? Color.green : Color.red)
                        Label("Lockdownd session with pairing file (TLS)", systemImage: "clock.badge.questionmark")
                            .foregroundStyle(.secondary)
                        Text("Delivery is designed to run over this same phone: pairing file -> tunnel -> lockdownd on port 62078. The Home Refresh probes the first steps for real; the TLS session and restore are not built yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Section("Engine status") {
                        Text("These files are the real payload, written in this app's container. Sending them to the system needs the on-device restore engine over the loopback WireGuard tunnel, which is not verified on iOS 26.6.1 yet — so nothing has been sent to the device.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("After a real apply: restart manually. This app cannot reboot your iPhone.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
                .navigationTitle("Apply")
                .toolbar {
                    Button("Done") { showSheet = false }
                }
            }
        }
    }
}
