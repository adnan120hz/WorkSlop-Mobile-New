# WorkSlop — Mobile (New)

Versi mobile baru WorkSlop, dibangun dari nol (bukan fork). Target fitur =
paritas WorkSlop Desktop v14.0 dengan dua jalur kirim yang sama seperti di
desktop untuk iOS 26:

- **Partial restore** untuk SEMUA tweak iOS 26, termasuk set Liquid Glass
  reguler. (Tweak desktop lama Beta 1 sudah dihapus maintainer dan tidak
  ada di sini.)
- **Full backup → payload → modify → full restore** khusus tweak hasil
  audit S8 (Liquid Glass Terbaru: `SolariumForceFallback` →
  `com.apple.SwiftUI.plist`, 2 key lock-screen, key specular) — full
  backup semua data, sama seperti desktop.
- Menu **Full Backup / Protective Backup TIDAK ada** di mobile (catatan
  sistemnya tetap dipakai internal). Menyimpan backup dari app ke Files
  terlalu berat; jalur iOS 27 desktop (protective backup: foto, video,
  pesan, kontak, data Apple ID/settings, keychain) tidak diangkut ke UI
  mobile.
- Menu **Passcode Theme TIDAK ada** di mobile (di desktop tetap ada).
- Katalog fitur mencerminkan section desktop (Liquid Glass, Status Bar,
  SpringBoard, Internal Options, Custom Icons). Section desktop
  "Feature Flags" sengaja tidak diangkut: kanal kirimnya terbukti
  tertutup di iOS 26.6.1 retail, jadi tidak bisa ditawarkan dengan jujur.
- File pairing = `.plist` hasil `idevicepair pair`, diimpor sekali di
  Settings dan disimpan di container app.
- Settings punya opsi **3 UI** (WorkSlop v4 / Nugget / Modern) yang
  benar-benar mengubah tema app.

Status jujur saat ini:

- Kerangka UI (Home, Liquid Glass, Tweaks, Settings) mencerminkan desktop.
- Fitur terkunci **hanya** bila iOS device di luar jendela dukungannya;
  iOS yang mendukung = terbuka, sama seperti desktop. Toggle memilih
  (staging) tweak, persis desktop.
- App ini **belum punya mesin restore on-device yang terverifikasi**.
  Tombol Apply menyatakan itu apa adanya — file pairing terimpor bukan
  bukti kirim, dan tidak ada restore/progress/"terkirim" palsu.
- Mata rantai yang belum terbukti: sesi restore loopback dari sandbox app
  di iOS 26.6.1. Wajib lulus spike verifikasi sebelum Apply menjalankan
  apa pun. Gagal spike = arah app dilaporkan mati, bukan dikirim rusak.
