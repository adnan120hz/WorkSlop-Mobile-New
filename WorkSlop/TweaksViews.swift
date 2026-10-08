import SwiftUI

/// List chrome per UI variant: main = inset grouped cards,
/// Nugget / Nugget Modern = plain lists (rows draw their own shape).
struct ThemedListStyle: ViewModifier {
    let style: UIStyle

    func body(content: Content) -> some View {
        // Room under the floating tab bar; contentMargins needs
        // iOS 17, the app floor is iOS 16 - branch for it.
        if #available(iOS 17.0, *) {
            AnyView(content
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 96, for: .scrollContent))
        } else {
            AnyView(content.listStyle(.insetGrouped))
        }
    }
}

/// Row backgrounds follow the UI color (purple/blue) as the same
/// pale wash the cards use, so no menu shows plain white blocks
/// and nothing turns saturated; Nugget keeps the system background.
struct ThemedRows: ViewModifier {
    let style: UIStyle

    func body(content: Content) -> some View {
        content.listRowBackground(
            style == .nugget ? nil : style.tint.opacity(0.18))
            .listRowSeparatorTint(style == .nugget ? nil : style.tint.opacity(0.25))
    }
}

/// One feature row. The toggle stages the feature (selection only, like
/// the desktop). A feature is locked ONLY when this device's iOS is
/// outside its support window — supported iOS renders it open.
struct FeatureRow: View {
    let feature: Feature
    @EnvironmentObject private var selection: SelectionStore
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue
    @State private var showInfo = false

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    /// Explanation text for the info sheet: what the tweak writes,
    /// where, and through which route — from the payload spec itself.
    private var explanation: String {
        var lines: [String] = []
        lines.append(feature.subtitle)
        if let spec = PayloadSpecCatalog.all.first(where: { $0.featureID == feature.id }) {
            for w in spec.writes {
                if let key = w.key {
                    lines.append("Writes \(key) to \(w.filePath) (\(w.domain.rawValue)).")
                } else if let target = w.fileTarget {
                    lines.append("Target: \(target) at \(w.filePath) (\(w.domain.rawValue)).")
                }
                if let condition = w.condition {
                    lines.append(condition)
                }
            }
            if let note = spec.note {
                lines.append(note)
            }
        }
        lines.append("Route: \(feature.routeSummary). Support: \(feature.window.label).")
        if feature.id == "lg-latest" {
            lines.append("Build gate: iOS 26.6.x (23G82/23G83) only - the desktop arms this set on those builds.")
        }
        if feature.id == "status-bar" {
            lines.append("Classic overrides are iOS 26.x; on iOS 27 only the carrier names apply.")
        }
        return lines.joined(separator: "\n\n")
    }

    private var availability: Availability {
        feature.availability(for: DeviceInfo.iosVersion)
    }

    /// Toggle is live only when the iOS supports the tweak AND the
    /// pairing-file + VPN gate is open.
    private var toggleEnabled: Bool {
        availability.isEnabled && ActivationGate.unlocked
    }

    private var infoButton: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("info-\(feature.id)")
    }

    private var toggle: some View {
        Toggle("", isOn: Binding(
            get: { selection.isOn(feature.id) },
            set: { selection.set(feature.id, $0) }))
            .labelsHidden()
            .disabled(!toggleEnabled)
            .accessibilityIdentifier("toggle-\(feature.id)")
    }

    var body: some View {
        Group {
            switch style {
            case .nugget:
                // Compact gray rows: single stack, no chips.
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.title)
                            .font(.callout)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(feature.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if !availability.isEnabled {
                            Text(availability.chipText ?? "")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 4)
                    infoButton
                    toggle
                }
                .padding(12)
                .cardSurface(style, glass: true, radius: 26)
            case .modern:
                // Card rows on a purple-tinted plate.
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(feature.subtitle)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            StatusChip(text: feature.routeShort)
                            if let chip = availability.chipText {
                                StatusChip(text: chip, warn: true)
                            }
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 8)
                    infoButton
                    toggle
                }
                .padding(10)
                .cardSurface(style, glass: true)
            case .workslop:
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(feature.subtitle)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            StatusChip(text: feature.routeShort)
                            if let chip = availability.chipText {
                                StatusChip(text: chip, warn: true)
                            }
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 8)
                    infoButton
                    toggle
                }
                .padding(10)
                .cardSurface(style, glass: true)
            }
        }
        .opacity(availability.isEnabled ? 1 : 0.6)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .sheet(isPresented: $showInfo) {
            NavigationStack {
                ScrollView {
                    Text(explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationTitle(feature.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Done") { showInfo = false }
                }
            }
        }
    }
}

struct LiquidGlassView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.modern.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .modern }

    private var latest: [Feature] {
        FeatureCatalog.features(in: "Liquid Glass").filter { $0.id == "lg-latest" }
    }

    private var regular: [Feature] {
        FeatureCatalog.features(in: "Liquid Glass").filter { $0.id != "lg-latest" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground(animated: false)
                List {
                Section {
                    LockBanner()
                }
                Section {
                    ForEach(latest) { feature in
                        FeatureRow(feature: feature)
                    }
                } header: {
                    Text("Liquid Glass (Latest) — S8")
                } footer: {
                    Text("SolariumForceFallback is read live by DesignLibrary from com.apple.SwiftUI on iOS 26.6.1 (firmware-verified). Its on-screen effect is not proven — an isolated device test decides it (full backup first, Low Power Mode off, reboot after apply).")
                }

                Section {
                    ForEach(regular) { feature in
                        FeatureRow(feature: feature)
                    }
                } header: {
                    Text("Liquid Glass")
                } footer: {
                    Text("The regular set: Partial restore on iOS 26, Full backup \u{2192} modify \u{2192} restore on iOS 27 - the same split as desktop.")
                }

                Section {
                    ApplySection()
                        .cardedRow(style, glass: true)
                }
                }
                .scrollContentBackground(.hidden)
            }
            .modifier(ThemedListStyle(style: style))
                .modifier(ThemedRows(style: style))
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Liquid Glass")
        }
    }
}

