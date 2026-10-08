import SwiftUI

@main
struct WorkSlopApp: App {
    @AppStorage("seenIntro") private var seenIntro = false
    @State private var showIntro = false

    /// iOS line this build supports: iOS 16 through 27. Up to the
    /// latest iOS 26 the tweaks ride the partial restore; on iOS 27
    /// everything rides the full backup -> modify -> restore flow,
    /// like the desktop. Anything outside the line gets the
    /// full-screen notice instead of an app that cannot serve it.
    private var iosSupported: Bool {
        let v = DeviceInfo.iosVersion
        return (16...27).contains(v.major)
    }

    var body: some Scene {
        WindowGroup {
            if iosSupported {
                ContentView()
                    .sheet(isPresented: $showIntro) { IntroView() }
                    .onAppear {
                        // Demo/screenshot runs (-DemoIOS26) land
                        // straight on Home, no intro sheet.
                        if !seenIntro,
                           !ProcessInfo.processInfo.arguments.contains("-DemoIOS26") {
                            showIntro = true
                        }
                    }
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
                Text("This device is running iOS \(DeviceInfoEx.fullVersion). WorkSlop 14.0 supports iOS 16.0 through 27.x.")
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
