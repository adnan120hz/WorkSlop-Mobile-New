import SwiftUI

@main
struct WorkSlopApp: App {
    @AppStorage("seenIntro") private var seenIntro = false
    @State private var showIntro = false

    /// iOS line this build supports, patch included in the check via
    /// major/minor gates: every supported tweak window lives inside
    /// iOS builds inside the desktop 16.0 to <27.0 support line.
    /// Anything outside it gets the
    /// full-screen notice instead of an app that cannot serve them.
    private var iosSupported: Bool {
        // Desktop support line (is_version_supported): 16.0 <= v < 27.0.
        let v = DeviceInfo.iosVersion
        return (v.major == 16) || (17...26).contains(v.major)
    }

    var body: some Scene {
        WindowGroup {
            if iosSupported {
                ContentView()
                    .sheet(isPresented: $showIntro) { IntroView() }
                    .onAppear { if !seenIntro { showIntro = true } }
            } else {
                UnsupportedIOSView()
            }
        }
    }
}

/// Full-screen block for devices outside the supported iOS line.
/// Honest and final: no app UI behind it, just the facts.
struct UnsupportedIOSView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.octagon")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                Text("iOS version not supported")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("This device is running iOS \(DeviceInfoEx.fullVersion). WorkSlop 14.0 supports iOS 16.0 through 26.x.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("The app will not open on this iOS. Nothing was changed on your device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding()
        }
    }
}
