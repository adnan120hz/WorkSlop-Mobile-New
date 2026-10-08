import UIKit

/// iOS 18 stock icon gallery (from the user's icon pack,
/// "iOS 18 App Icons by catwithabaloon"). Two tables on the Custom
/// Icons page: Light and Dark. Tapping one adds it as a custom icon
/// entry (name + bundle ID + the icon image) - bundle IDs verified
/// against the iTunes lookup for each app. Icons are 60x60 PNG,
/// exactly as supplied in the pack. The pack's third variant
/// (tinted) and artworks that could not be identified with
/// certainty are not shipped.
struct IOS18Icon: Identifiable {
    let name: String
    let bundleID: String
    let slug: String
    var id: String { slug }
}

enum IOS18IconCatalog {
    static let all: [IOS18Icon] = [
        IOS18Icon(name: "Shortcuts", bundleID: "com.apple.shortcuts", slug: "shortcuts"),
        IOS18Icon(name: "App Store", bundleID: "com.apple.AppStore", slug: "app-store"),
        IOS18Icon(name: "Settings", bundleID: "com.apple.Preferences", slug: "settings"),
        IOS18Icon(name: "Numbers", bundleID: "com.apple.Numbers", slug: "numbers"),
        IOS18Icon(name: "Pages", bundleID: "com.apple.Pages", slug: "pages"),
        IOS18Icon(name: "Keynote", bundleID: "com.apple.Keynote", slug: "keynote"),
        IOS18Icon(name: "Books", bundleID: "com.apple.iBooks", slug: "books"),
        IOS18Icon(name: "Calculator", bundleID: "com.apple.calculator", slug: "calculator"),
        IOS18Icon(name: "Calendar", bundleID: "com.apple.mobilecal", slug: "calendar"),
        IOS18Icon(name: "Camera", bundleID: "com.apple.camera", slug: "camera"),
        IOS18Icon(name: "Music Classical", bundleID: "com.apple.music.classical", slug: "music-classical"),
        IOS18Icon(name: "Clock", bundleID: "com.apple.mobiletimer", slug: "clock"),
        IOS18Icon(name: "Compass", bundleID: "com.apple.compass", slug: "compass"),
        IOS18Icon(name: "Contacts", bundleID: "com.apple.AddressBook", slug: "contacts"),
        IOS18Icon(name: "FaceTime", bundleID: "com.apple.facetime", slug: "facetime"),
        IOS18Icon(name: "Files", bundleID: "com.apple.DocumentsApp", slug: "files"),
        IOS18Icon(name: "Clips", bundleID: "com.apple.clips", slug: "clips"),
        IOS18Icon(name: "Find My", bundleID: "com.apple.findmy", slug: "find-my"),
        IOS18Icon(name: "Fitness", bundleID: "com.apple.Fitness", slug: "fitness"),
        IOS18Icon(name: "GarageBand", bundleID: "com.apple.mobilegarageband", slug: "garageband"),
        IOS18Icon(name: "Health", bundleID: "com.apple.Health", slug: "health"),
        IOS18Icon(name: "Home", bundleID: "com.apple.Home", slug: "home"),
        IOS18Icon(name: "Magnifier", bundleID: "com.apple.Magnifier", slug: "magnifier"),
        IOS18Icon(name: "Mail", bundleID: "com.apple.mobilemail", slug: "mail"),
        IOS18Icon(name: "Maps", bundleID: "com.apple.Maps", slug: "maps"),
        IOS18Icon(name: "Measure", bundleID: "com.apple.measure", slug: "measure"),
        IOS18Icon(name: "Music", bundleID: "com.apple.Music", slug: "music"),
        IOS18Icon(name: "News", bundleID: "com.apple.news", slug: "news"),
        IOS18Icon(name: "Notes", bundleID: "com.apple.mobilenotes", slug: "notes"),
        IOS18Icon(name: "Passwords", bundleID: "com.apple.Passwords", slug: "passwords"),
        IOS18Icon(name: "Phone", bundleID: "com.apple.mobilephone", slug: "phone"),
        IOS18Icon(name: "Photos", bundleID: "com.apple.mobileslideshow", slug: "photos"),
        IOS18Icon(name: "Podcasts", bundleID: "com.apple.podcasts", slug: "podcasts"),
        IOS18Icon(name: "Reminders", bundleID: "com.apple.reminders", slug: "reminders"),
        IOS18Icon(name: "Apple TV Remote", bundleID: "com.apple.TVRemote", slug: "apple-tv-remote"),
        IOS18Icon(name: "Safari", bundleID: "com.apple.mobilesafari", slug: "safari"),
        IOS18Icon(name: "Stocks", bundleID: "com.apple.stocks", slug: "stocks"),
        IOS18Icon(name: "Apple Store", bundleID: "com.apple.store.Jolly", slug: "apple-store"),
        IOS18Icon(name: "Swift Playgrounds", bundleID: "com.apple.Playgrounds", slug: "swift-playgrounds"),
        IOS18Icon(name: "TestFlight", bundleID: "com.apple.TestFlight", slug: "testflight"),
        IOS18Icon(name: "Tips", bundleID: "com.apple.tips", slug: "tips"),
        IOS18Icon(name: "Translate", bundleID: "com.apple.Translate", slug: "translate"),
        IOS18Icon(name: "Voice Memos", bundleID: "com.apple.VoiceMemos", slug: "voice-memos"),
        IOS18Icon(name: "Wallet", bundleID: "com.apple.Passbook", slug: "wallet"),
        IOS18Icon(name: "Watch", bundleID: "com.apple.Bridge", slug: "watch"),
        IOS18Icon(name: "Weather", bundleID: "com.apple.weather", slug: "weather"),
        IOS18Icon(name: "Messages", bundleID: "com.apple.MobileSMS", slug: "messages"),
        IOS18Icon(name: "iMovie", bundleID: "com.apple.iMovie", slug: "imovie"),
        IOS18Icon(name: "Apple Sports", bundleID: "com.apple.sports", slug: "apple-sports"),
        IOS18Icon(name: "TV", bundleID: "com.apple.tv", slug: "tv"),
        IOS18Icon(name: "Shazam", bundleID: "com.shazam.Shazam", slug: "shazam"),
    ]

    static func imageData(slug: String, dark: Bool) -> Data? {
        let sub = dark ? "iOS18Icons/Dark" : "iOS18Icons/Light"
        guard let url = Bundle.main.url(forResource: slug, withExtension: "png", subdirectory: sub)
        else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Decoded gallery thumbnails, cached for the whole session.
    /// The gallery lists ~100 rows; decoding PNG data on every
    /// render was a real source of scroll lag.
    private static let imageCache = NSCache<NSString, UIImage>()

    static func image(slug: String, dark: Bool) -> UIImage? {
        let key = (dark ? "d:" : "l:") + slug as NSString
        if let hit = imageCache.object(forKey: key) { return hit }
        guard let data = imageData(slug: slug, dark: dark),
              let img = UIImage(data: data) else { return nil }
        imageCache.setObject(img, forKey: key)
        return img
    }

    static func hasDark(slug: String) -> Bool {
        Bundle.main.url(forResource: slug, withExtension: "png", subdirectory: "iOS18Icons/Dark") != nil
    }
}
