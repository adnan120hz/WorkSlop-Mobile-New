import SwiftUI

/// One feature row. The toggle stages the feature (selection only, like
/// the desktop). A feature is locked ONLY when this device's iOS is
/// outside its support window — supported iOS renders it open.
struct FeatureRow: View {
    let feature: Feature
    @EnvironmentObject private var selection: SelectionStore

    private var availability: Availability {
        feature.availability(for: DeviceInfo.iosVersion)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(.body.weight(.medium))
                    Text(feature.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { selection.isOn(feature.id) },
                    set: { selection.set(feature.id, $0) }))
                    .labelsHidden()
                    .disabled(!availability.isEnabled)
                    .accessibilityIdentifier("toggle-\(feature.id)")
            }
            HStack(spacing: 6) {
                StatusChip(text: feature.route.rawValue)
                if let chip = availability.chipText {
                    StatusChip(text: chip, warn: true)
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(availability.isEnabled ? 1 : 0.6)
    }
}

/// The Apply action. This app has NO verified on-device restore engine
/// yet, so Apply never pretends: it states plainly that an imported
/// pairing file is not a proven delivery, and that nothing was sent.
/// It becomes a real restore only after the loopback engine passes its
/// verification spike on iOS 26.6.1.
struct ApplyBar: View {
    @EnvironmentObject private var selection: SelectionStore
    @State private var showEngineNote = false

    var body: some View {
        Button {
            showEngineNote = true
        } label: {
            Text("Apply (\(selection.staged.count) tweak)")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(selection.staged.isEmpty)
        .accessibilityIdentifier("apply-button")
        .alert("Mesin belum tersambung", isPresented: $showEngineNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("File pairing yang terimpor tidak sama dengan mesin restore yang terbukti. Belum ada yang dikirim ke device — Apply aktif hanya sesudah sesi restore on-device lolos verifikasi di iOS 26.6.1.")
        }
    }
}

struct LiquidGlassView: View {
    private var latest: [Feature] {
        FeatureCatalog.features(in: "Liquid Glass").filter { $0.id == "lg-latest" }
    }

    private var regular: [Feature] {
        FeatureCatalog.features(in: "Liquid Glass").filter { $0.id != "lg-latest" }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(latest) { feature in
                        FeatureRow(feature: feature)
                    }
                } header: {
                    Text("Liquid Glass (Terbaru) — S8")
                } footer: {
                    Text("SolariumForceFallback dibaca hidup oleh DesignLibrary dari com.apple.SwiftUI di iOS 26.6.1 (terverifikasi firmware). Efeknya di layar belum terbukti — diputus uji device terisolasi (backup penuh dulu, Low Power Mode mati, reboot sesudah apply).")
                }

                Section {
                    ForEach(regular) { feature in
                        FeatureRow(feature: feature)
                    }
                } header: {
                    Text("Liquid Glass")
                } footer: {
                    Text("Set reguler lewat partial restore, sama seperti desktop.")
                }

                Section {
                    ApplyBar()
                }
            }
            .navigationTitle("Liquid Glass")
        }
    }
}

struct TweaksView: View {
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Tweaks")
        }
    }
}
