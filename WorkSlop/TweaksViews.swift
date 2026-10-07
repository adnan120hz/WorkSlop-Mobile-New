import SwiftUI

/// List chrome per UI variant: main = inset grouped cards,
/// Nugget / Nugget Modern = plain lists (rows draw their own shape).
struct ThemedListStyle: ViewModifier {
    let style: UIStyle

    func body(content: Content) -> some View {
        if style == .workslop {
            content.listStyle(.insetGrouped)
        } else {
            content.listStyle(.plain)
        }
    }
}

/// One feature row. The toggle stages the feature (selection only, like
/// the desktop). A feature is locked ONLY when this device's iOS is
/// outside its support window — supported iOS renders it open.
struct FeatureRow: View {
    let feature: Feature
    @EnvironmentObject private var selection: SelectionStore
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue
    @State private var showInfo = false

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

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
        lines.append("Route: \(feature.route.rawValue). Support: \(feature.window.label).")
        lines.append("Sending needs the on-device restore engine, which is not verified on iOS 26.6.1 yet — staging only for now.")
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
                    }
                    Spacer(minLength: 4)
                    infoButton
                    toggle
                }
                .padding(.vertical, 1)
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
                        StatusChip(text: feature.route.rawValue)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 8)
                    infoButton
                    toggle
                }
                .padding(10)
                .background(Color.white.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
                            StatusChip(text: feature.route.rawValue)
                            if let chip = availability.chipText {
                                StatusChip(text: chip, warn: true)
                            }
                            if availability.isEnabled && !ActivationGate.unlocked {
                                StatusChip(text: "Needs pairing file + VPN", warn: true)
                            }
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 8)
                    infoButton
                    toggle
                }
                .padding(.vertical, 4)
            }
        }
        .opacity(availability.isEnabled ? 1 : 0.6)
        .listRowBackground(
            style == .modern
                ? Color(red: 0.35, green: 0.30, blue: 0.92).opacity(0.07)
                : nil)
        .listRowSeparator(style == .modern ? .hidden : .automatic)
        .sheet(isPresented: $showInfo) {
            NavigationStack {
                ScrollView {
                    Text(explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
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
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    private var latest: [Feature] {
        FeatureCatalog.features(in: "Liquid Glass").filter { $0.id == "lg-latest" }
    }

    private var regular: [Feature] {
        FeatureCatalog.features(in: "Liquid Glass").filter { $0.id != "lg-latest" }
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
                    Text("The regular set rides partial restore, same as on desktop.")
                }

                Section {
                    ApplySection()
                }
                }
                .scrollContentBackground(.hidden)
            }
            .modifier(ThemedListStyle(style: style))
            .navigationTitle("Liquid Glass")
        }
    }
}

