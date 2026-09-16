# Food Rescue — Mobile App (Flutter)

Aplikasi mobile Food Rescue: 1 APK dengan 3 role (User, Toko, Kurir).
Bagian dari proyek Food Rescue — lihat PRD di dokumen tim.

## Tech Stack
- Flutter (Android, siap dikembangkan ke iOS)
- State management: Riverpod / Bloc (tentukan salah satu, update baris ini setelah disepakati)
- Firebase Auth (Google Sign-In + email/password)
- google_maps_flutter, geolocator, geocoding
- camera / image_picker (untuk deteksi nutrisi via kamera)
- google_ml_kit (OCR scan struk/kemasan)

## Struktur Folder
```
lib/
  core/              # config, network client, utils, shared widgets
  features/
    auth/            # login, register, pilih role
    user/            # jelajah, pesanan, dampak, profile, komunitas, asisten_ai
    toko/            # analisis, tambah_barang, pengolahan_limbah, komunitas, rating, profil
    kurir/           # toggle_status, pesanan_masuk, pesanan_aktif, riwayat, profil
    admin/           # (jika ada bagian admin di mobile, biasanya kosong — admin di web)
assets/
  images/
  icons/
test/
```

## Setup
```bash
flutter pub get
flutter run
```

## Branching
- `main` → stabil / rilis
- `dev` → development aktif
- `feature/nama-fitur` → per fitur, merge ke `dev` via Pull Request

## Environment
Salin `.env.example` menjadi `.env` dan isi kredensial (API base URL, Firebase config, Google Maps API key, dll). Jangan commit `.env`.
