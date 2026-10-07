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
                        FeatureRow(feature: feature)
                        Toggle("Enable Status Bar Modifications", isOn: $masterOn)
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
                        ForEach(FeatureCatalog.features(in: "Daemons")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("Daemons")
                    } footer: {
                        Text("Daemon toggles write the disabled-daemons list the desktop manages. A disabled daemon stays off until the toggle is removed and the device restarts.")
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
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
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
                        Text("Cowabunga icon packs can be browsed on the web; download a pack there, then add its images above one by one with the matching bundle IDs.")
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
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        PhotosPicker(selection: $picked, matching: .images) {
                            Label("Import image", systemImage: "photo")
                        }
                    }
                }
                .navigationTitle("Icon")
                .toolbar {
                    Button("Done") {
                        CustomIconStore.save(entries)
                        editingIndex = nil
                    }
                }
                .onChange(of: picked) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self) {
                            entries[i].imageData = data
                            CustomIconStore.save(entries)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - PosterBoard

struct PosterBoardView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                    Section {
                        ForEach(FeatureCatalog.features(in: "PosterBoard")) { feature in
                            FeatureRow(feature: feature)
                        }
                    } header: {
                        Text("PosterBoard")
                    } footer: {
                        Text("Lock Screen poster (PosterBoard) templates and collections, delivered like the desktop PosterBoard page.")
                    }
                    Section {
                        ApplySection()
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(ThemedListStyle(style: style))
            }
            .navigationTitle("PosterBoard")
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
            Text("Apply puts the staged tweaks on this device over the loopback WireGuard tunnel to this same phone. The full payload is verified first; if any check fails, nothing is sent.")
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
                        Text("The apply runs over this same phone: pairing file -> tunnel -> lockdownd on port 62078. The Home Refresh probes the first steps for real.")
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
