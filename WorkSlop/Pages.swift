import SwiftUI
import PhotosUI

// MARK: - Status Bar (desktop page parity, staged values)

/// All desktop Status Bar page controls, staged on-device. The values
/// ride the 0xF68 `statusBarOverrides` struct (field layout
/// firmware-verified on iOS 26.6.1). The struct itself is assembled
/// from the device's captured base during a restore session — never
/// fabricated in the app — so this page stages values, honestly.
struct StatusBarView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue
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

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
            }
            .navigationTitle("Status Bar")
        }
    }
}

// MARK: - Daemons

struct DaemonsView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
            }
            .navigationTitle("Daemons")
        }
    }
}

// MARK: - Apple Internal

struct AppleInternalView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue
    @State private var entries: [CustomIconEntry] = CustomIconStore.load()
    @State private var picked: PhotosPickerItem?
    @State private var editingIndex: Int?

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                        Link(destination: URL(string: "https://github.com/leminlimez/Cowabunga")!) {
                            Label("Cowabunga bookmark icons (web)", systemImage: "safari")
                        }
                        .accessibilityIdentifier("icons-cowabunga")
                        Text("Install bookmark icons from the Cowabunga website, or add your own below: PNG image, app name and bundle ID are all required.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                            Label("Import image (saved as PNG)", systemImage: "photo")
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
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue
    @State private var importing = false
    @State private var note: String?
    @State private var files: [String] = TendiesStore.list()

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        LockBanner()
                    }
                    Section {
                        Button("Import files (.tendies / .batter)") { importing = true }
                            .accessibilityIdentifier("pb-import")
                        if files.isEmpty {
                            Text("No files imported yet. PosterBoard has nothing to deliver until you import at least one .tendies file.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(files, id: \.self) { name in
                                Label(name, systemImage: "doc")
                                    .font(.footnote)
                            }
                            .onDelete { offsets in
                                TendiesStore.delete(at: offsets, from: files)
                                files = TendiesStore.list()
                            }
                        }
                        if let note {
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Your PosterBoard files")
                    } footer: {
                        Text("Up to 10 descriptor files ride one apply (desktop cap). Imported files are copied into the app container.")
                    }
                    Section {
                        ForEach(FeatureCatalog.features(in: "PosterBoard")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Modes")
                    } footer: {
                        Text("Tendies / Templates / Video ride the desktop PosterBoard route: targeted container backup -> modify -> partial restore. Delivery happens from the Apply sections on the tweak pages once the engine runs - never a direct apply here.")
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
            }
            .navigationTitle("PosterBoard")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.data],
                          allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    var imported = 0
                    for url in urls {
                        let ext = url.pathExtension.lowercased()
                        guard ext == "tendies" || ext == "batter" else { continue }
                        let scoped = url.startAccessingSecurityScopedResource()
                        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        if TendiesStore.save(url: url) { imported += 1 }
                    }
                    files = TendiesStore.list()
                    note = imported > 0
                        ? "Imported \(imported) file(s). They are staged for the next engine apply."
                        : "Nothing imported - only .tendies and .batter files are accepted."
                case .failure:
                    note = "Import cancelled."
                }
            }
        }
    }
}

// MARK: - Tendies store (PosterBoard imports)

enum TendiesStore {
    static var dir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tendies", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    static func list() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: dir.path))?.sorted() ?? []
    }

    static func save(url: URL) -> Bool {
        guard list().count < 10 else { return false }
        let dest = dir.appendingPathComponent(url.lastPathComponent)
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

    static func delete(at offsets: IndexSet, from files: [String]) {
        for i in offsets {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(files[i]))
        }
    }
}

// MARK: - SpringBoard tweaks

struct SpringBoardView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
    @State private var built: BuiltPayload?
    @State private var showSheet = false
    @State private var confirmCancel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apply builds the real payload from your staged tweaks on this phone. Delivery to the system runs over the loopback VPN tunnel with your pairing file - and only once the on-device restore engine passes its checks; if any check fails, nothing is sent.")
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
            Text("Cancel here unstages everything before anything is sent. During a real apply, cancelling terminates the restore session: turn off WireGuard, then force-restart (Volume Up, Volume Down, hold Side button). After a successful apply you restart manually — this app cannot reboot your iPhone.")
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
                    Section("Engine checks (pairing-file route)") {
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
                .navigationTitle("Apply")
                .toolbar {
                    Button("Done") { showSheet = false }
                }
            }
        }
    }
}
