# tubes_pm_kelompok1

## Info
Nama aplikasi: Moneygement

Tim Pengembang: Kelompok 1

- Timothy Manuel Chandra - 231402062
  Front-end & Back-end
- Perry Saputra Halim - 231402087
  Front-end & Back-end
- Muhammad Hilmiy Arifqi - 231402102
  UI/UX design
- Nur Bayu - 231402105
  Documentation & Back-end
- IzuKhairi Misrawi Rohali - 231402112
  UI/UX design
- Fadhil Al Harits Lubis - 231402116
  Documentation & Front-end

## Desc
Moneygement adalah aplikasi berbasis mobile yang dirancang untuk memudahkan penggunanya dalam mengatur dan mengelola keuangannya. Mulai dari pencatatan pengeluaran & pemasukan, serta rangkuman pengeluaran & pemasukan per jangka waktu yang dapat ditentukan pengguna sendiri.

## UI Design
[Link Figma](https://www.figma.com/design/YIaG2HQBSinfTLiUmwndMx/Figma-Project-PM-Kelompok-1?node-id=0-1&t=BUz2gTUJJ7SYeMYS-1)

## Features

### Guest / Pengunjung
- Melakukan Register
- Melakukan Log In

### User
#### Autentikasi
- Melakukan Login

#### Dashboard/Home
- Melihat jumlah saldo yang dimiliki saat ini
- Melihat total pengeluaran dan pemasukan
- Melihat aktivitas terkini sesuai dengan filter yang dipilih
- Menambahkan jumlah saldo/pemasukan
- Mengedit informasi pengeluaran dan pemasukan
- Menghapus pengeluaran dan pemasukan

#### Kalender
- Melihat daftar pengeluaran dan pemasukan per hari dalam kalender
- Mengedit informasi pengeluaran dan pemasukan
- Menghapus pengeluaran dan pemasukan

#### Tambah Pengeluaran
- Menambahkan pengeluaran baru

#### Analitik
- Melihat laporan pengeluaran bulanan berupa perbandingan persentase tiap kategori

#### Profile
- Melihat profil
- Mengubah nama/username
- Mengubah password
- Melakukan Log Out

## Library
### Firebase Core
#### Kegunaan:
Library ini digunakan sebagai jembatan penghubung antara aplikasi dengan Firebase.

### Firebase Auth
#### Kegunaan:
Library ini digunakan untuk mengelola Sign Up atau Log In pada aplikasi seperti pengelolaan email, password, dan lainnya.

### Google Sign-In
#### Kegunaan:
Library ini digunakan secara spesifik untuk mengelola proses login menggunakan akun Google.

### Cloud Firestore
#### Kegunaan:
Library ini digunakan sebagai database berjenis NoSQL untuk menyimpan data aplikasi.

### Table Calendar
#### Kegunaan:
Table Calendar adalah library yang menyediakan widget kalender. Widget ini dapat dikostumisasi sesuai dengan gaya yang ingin kita tampilkan.

### FL Chart
#### Kegunaan:
FL Chart adalah library yang menyediakan grafik kustom dalam Flutter. Library ini mendukung Line Chart, Bar Chart, Pie Chart, Scatter Chart, dan Radar Chart.

### Cupertino Icons
#### Kegunaan:
Library ini menyediakan ikon-ikon aplikasi yang bergaya iOS.

### SplashScreen
#### Kegunaan:
Library atau fitur ini digunakan sebagai tampilan awal atau layar pembuka saat aplikasi pertama kali dijalankan. Biasanya untuk memperkenalkan logo, nama aplikasi, dan proses inisialisasi aplikasi.

## Permission
### INTERNET
Memberikan izin kepada aplikasi untuk mengakses jaringan internet. Izin ini penting agar aplikasi dapat mengakses ke internet seperti untuk kebutuhan Log In.

#### ACCESS_NETWORK_STATE
Memberikan izin kepada aplikasi untuk memeriksa status jaringan (apakah perangkat terhubung ke sumber jaringan).

## Requirements
#### Syarat
Beberapa syarat environment agar aplikasi dapat berjalan dengan lancar:
- **Dart SDK**: Versi terbaru (>= 3.9.2)
- **Android Studio**: Versi terbaru dengan 
- **Gradle**: Sesuai dengan versi Android Studio

#### Instalasi dan Setup
1. Install Android Studio
- Download dan install Android Studio melalui [Android Studio Official Website](https://developer.android.com/studio).
2. Install Dart SDK
- Download dan install Dart SDK melalui [Dart SDK Official Website](https://dart.dev/get-dart).
3. Clone Repository
- Clone repository di bawah ini ke lokal komputer,
  `https://github.com/timoresing/moneygement.git`
4. Buka Android Studio dan open project yang sudah diclone.
5. Jalankan command di bawah agar semua dependencies terinstall.
`flutter pub get`
6. Download dan tambahkan Virtual Device berupa Android Emulator di Android Studio.
7. Jalankan aplikasi dengan memilih Virtual Device yang tepat dan tekan tombol Play.

[//]: # (This project is a starting point for a Flutter application.)
[//]: # ()
[//]: # (A few resources to get you started if this is your first Flutter project:)

[//]: # ()
[//]: # (- [Lab: Write your first Flutter app]&#40;https://docs.flutter.dev/get-started/codelab&#41;)

[//]: # (- [Cookbook: Useful Flutter samples]&#40;https://docs.flutter.dev/cookbook&#41;)

[//]: # ()
[//]: # (For help getting started with Flutter development, view the)

[//]: # ([online documentation]&#40;https://docs.flutter.dev/&#41;, which offers tutorials,)

[//]: # (samples, guidance on mobile development, and a full API reference.)
