# FoodRescue Mobile

## Konfigurasi Google Sign-In

Login Google memakai ID token Google yang ditukar oleh backend melalui endpoint `/auth/google`.
Sebelum menjalankan aplikasi di perangkat Android:

1. Buat OAuth Client ID tipe **Web application** di Google Cloud Console. Masukkan client ID-nya ke `.env` sebagai `GOOGLE_SERVER_CLIENT_ID`.
2. Buat OAuth Client ID tipe **Android** dengan package `com.foodrescue.food_rescue_mobile`.
3. Daftarkan SHA-1 dan SHA-256 signing certificate dari build yang dipakai. Untuk debug, ambil dari Gradle signing report; untuk Play Store, gunakan App signing certificate di Play Console.
4. Pastikan backend memvalidasi audience token terhadap Web Client ID dan endpoint `/auth/google` mengembalikan `{ token, user }`.

Jangan commit client secret atau API key. Client ID OAuth boleh berada di konfigurasi aplikasi, tetapi secret tetap hanya di backend.

## Branding

Nama aplikasi Android/iOS adalah **FoodRescue**. Ikon launcher dibuat dari `assets/icons/Foodrescue.png`.
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
