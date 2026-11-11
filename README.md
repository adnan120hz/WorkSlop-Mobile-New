<p align="center">
  <img src="assets/workslop-icon.png" width="160" alt="WorkSlop Mobile icon">
</p>

# WorkSlop — Mobile (New)

WorkSlop Mobile by **adnan.120hz** — a no-jailbreak iOS customization app.
Sideload the IPA, import your pairing file once, and apply everything
straight from your iPhone. Licensed under **AGPL-3.0** (see `LICENSE`).

## v5.0

WorkSlop Mobile v5.0 (build 14, minimum iOS 26.0).

Download: [v5.0 release](https://github.com/adnan120hz/WorkSlop-Mobile-New/releases/tag/v5.0)
(IPA `WorkSlop-v5.0-license-darkicon-unsigned.ipa`, unsigned — sideload
it the way you sideloaded previous beta builds.)

### What's new in v5.0

- Liquid Glass menu for iOS 27 expanded from 8 to 32 rows (Blur Fill,
  StackedImageContainer, Allow HDR, Live Tuning, Calistoga, and more).
  The menu only shows tweaks that match your iOS version.
- Settings → License now opens an Upstream page with 10 sections
  describing where each part of the app comes from and the license it
  runs under (AGPL-3.0 and MIT parts).
- Dark Mode, plus a dark app icon that follows the system appearance.
- iOS 18 Flat Lock Screen section in PosterBoard.
- Photo-to-.tendies generator: turn your own photo into a PosterBoard
  wallpaper pack.
- Big-text popup when a backup is not encrypted (the apply preflight
  used to fail silently).
- Icon Themes: the duplicate set is gone, one set remains.

### Removed

- iOS 18 icon velum work.
### Before you apply

The warnings under v4 below still apply: Find My iPhone OFF, a
verified encrypted backup on your computer before any restore, VPN on,
Low Power Mode OFF, app in the foreground, screen ON.

## v4 — device-test build

This is a device-test build. It is CI-green and binary-verified only.
Nothing new in it is device-proven yet. Test one thing at a time and
send logs or photos for everything you try.

### Before you apply — read this first

- Find My iPhone must be OFF before applying. Turn it off in
  Settings → [your name] → Find My → Find My iPhone, apply your tweaks,
  and you can turn it back on afterwards.
- Before every test: VPN on, Low Power Mode OFF, app in the foreground,
  screen ON. After a restore, restart the iPhone manually.
- Partial Restore warning: on iOS 27, Partial Restore can sign you out
  of iCloud and delete files from apps and Files. There are past cases
  of photo and video loss after Normal and Partial restores on iOS 27.
  Do NOT run it on your main phone unless you already have a verified
  encrypted backup on your computer. That backup is your real safety
  net. This app is not.
- All Data Backup has never completed a full pull on a real phone, and
  Restore All Data has never been proven on a device. Do not rely on
  either as your only backup.

### Support

- **iOS 26 — Supported.** All features are active.
- **iOS 27.0 – 27.0.1 — Potential Supported** (24A437, 24A446).
- **iOS 27.2 beta 1 – beta 2 — Partially Supported.**
- **iOS 27.2 beta 3 and later — Patched** (not supported).
- The app requires iOS 26.0 or later to install. Per-feature blocks
  still apply.

On iOS 27 the Status Bar menu is hidden (Status Bar does not work on
iOS 27). On iOS 26 everything listed under Features is active.

### Features

- Liquid Glass tweaks
- Icon Themes
- Status Bar customisation (iOS 26 only)
- Apple Internal options
- Daemons control
- PosterBoard wallpapers (backup/restore path and new Apply path)
- Passcode themes
- Wallet card skins
- Remove Tweaks — undo applied tweaks and return the files to their
  defaults
- iOS 27 Partial Restore — a dedicated restore method for iOS 27
- All Data Backup — a full backup that keeps everything, including
  photos, videos, and app containers
- Restore All Data Backup — restores an All Data Backup package, with
  verification before restoring
- Live backup/restore size display on the Apply screen
- Supported iOS table in Settings

### Pairing file

On **iOS 27** the pairing file is generated inside WorkSlop itself —
Get Pairing File pairs the app as the host (turn on Developer Mode,
pair with host, enter the PIN). On **iOS 26** the `.plist` is created
on a computer with `idevicepair pair` or similar tools and imported
into the app. Either way it is set up once and stored in the app
container.

### Credits

- **adnan.120hz** — WorkSlop Mobile lead developer. Builds the app and
  its interface, builds new code, builds new tweaks, and builds the iOS
  system adaptations that make them work on each iOS version.
- Beta tester team (WorkSlop Mobile): Charlie, rfrz1d_, Davy, uggtx,
  Fayaz, alfndv1, s1gn.
- Engine and upstream contributors: see "Changes from upstream" below.

## Changes from upstream

- The interface is WorkSlop's own original UI (SwiftUI), designed and
  built for this app — no upstream interface is used.
- The apply engine is ported from the upstream project's apply pass,
  plus WorkSlop's own layers on top: the SQLite root-logging layer,
  the live size reporting, and the explicit keep-data flag for
  restores. The engine is no longer imported unmodified.
- The PosterBoard backup/restore path is ported from the upstream
  project's PosterboardTweak. The PosterBoard Apply path, passcode
  themes, and wallet skins are ported from a separate open-source
  fork (MIT licensed — see the per-file headers in
  `WorkSlop/Backend/` for the exact sources).
- Icon Themes are implemented as a WorkSlop payload producer (WebClip
  files at a HomeDomain path) riding the engine's delivery.
- Upstream engine and contributors: engine by [awesomenull] and
  [Wind0ws11Aero], building on [LeminLimez] (Nugget),
  [@mak5er](https://github.com/mak5er) (AirCard),
  [NeoSpring](https://github.com/rooootdev/neospring) by
  [@skadz108](https://github.com/skadz108),
  [@rooootdev](https://github.com/rooootdev) and
  [@neonmodder123](https://github.com/neonmodder123), 0xjonhnnydev
  (AirLift), [iTechExpert][iTechExpertTwitter] (SpringBoard/Internal
  options) and [Mikasa-san][Mikasa-sanGitHub]
  ([Quiet Daemon][QuietDaemonGitHub]).
- The project as a whole remains under AGPL-3.0, following the
  upstream license. WorkSlop's own additions are copyright
  adnan.120hz, under the same AGPL-3.0.

[awesomenull]: https://github.com/awesomenull-dev
[Wind0ws11Aero]: https://github.com/Wind0ws11Aero
[LeminLimez]: https://github.com/leminlimez
[iTechExpertTwitter]: https://x.com/iTechExpert21
[Mikasa-sanGitHub]: https://github.com/Mikasa-san
[QuietDaemonGitHub]: https://github.com/Mikasa-san/QuietDaemon
