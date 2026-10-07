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

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    private var availability: Availability {
        feature.availability(for: DeviceInfo.iosVersion)
    }

    private var toggle: some View {
        Toggle("", isOn: Binding(
            get: { selection.isOn(feature.id) },
            set: { selection.set(feature.id, $0) }))
            .labelsHidden()
            .disabled(!availability.isEnabled)
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
                    toggle
                }
                .padding(10)
                .background(Color.white.opacity(0.65))
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
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 8)
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
    }
}

/// The Apply action. This app has NO verified on-device restore engine
/// yet, so Apply never pretends: it states plainly that an imported
/// pairing file is not a proven delivery, and that nothing was sent.
/// It becomes a real restore only after the loopback engine passes its
/// verification spike on iOS 26.6.1.
struct ApplyBar: View {
    @EnvironmentObject private var selection: SelectionStore
    @State private var built: BuiltPayload?
    @State private var showSheet = false

    var body: some View {
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
                    ApplyBar()
                }
                }
                .scrollContentBackground(.hidden)
            }
            .modifier(ThemedListStyle(style: style))
            .navigationTitle("Liquid Glass")
        }
    }
}

struct TweaksView: View {
    @AppStorage("uiStyle") private var uiStyleRaw = UIStyle.workslop.rawValue

    private var style: UIStyle { UIStyle(rawValue: uiStyleRaw) ?? .workslop }

    var body: some View {
        NavigationStack {
            ZStack {
                AppleDriftBackground()
                List {
                ForEach(FeatureCatalog.sections.filter { $0 != "Liquid Glass" }, id: \.self) { section in
                    Section(section) {
                        ForEach(FeatureCatalog.features(in: section)) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                }

                Section {
                    ApplyBar()
                }
                }
                .scrollContentBackground(.hidden)
            }
            .modifier(ThemedListStyle(style: style))
            .navigationTitle("Tweaks")
        }
    }
}
