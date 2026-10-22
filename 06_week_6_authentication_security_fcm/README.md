# Minggu 5 - Local Storage Offline First

**Nama:** Faatihurrizki Prasojo

**NIM:** 244107020142

## Tujuan 
- Menjelaskan alur autentikasi (Firebase Auth / JWT / OAuth / Google Login) dan perbedaan ID token vs access token vs refresh token;
- Menyimpan token secara aman dengan secure storage serta menerapkan token refresh otomatis;
- Menjelaskan arsitektur FCM: app server, Firebase, dan perangkat;
- Meminta notification permission dan mengelola token lifecycle (`getToken`, `onTokenRefresh`);
- Membedakan notification payload vs data payload serta perilakunya pada state foreground, background, dan terminated;
- Menangani klik notifikasi (deep link dengan GoRouter) dan topic messaging;
- Menerapkan prinsip keamanan dasar aplikasi mobile (tidak menyimpan secret di kode, tidak log token).

#### Dokumentasi Praktikum
| Autentikasi & FCM Token | Home | Notifikasi | Isi Pengumuman |
| :---: | :---: |:---: | :---: |
| <img src="./Screenshot/sample1.jpeg" width="400"> | <img src="./Screenshot/sample2.jpeg" width="400"> | <img src="./Screenshot/sample3.jpeg" width="400"> |  <img src="./Screenshot/sample4.jpeg" width="400"> |
|Tampilan antarmuka login dan halaman utama setelah autentikasi berhasil, menampilkan FCM token unik perangkat untuk pengujian push notification. | Tampilan awal setelah berhasil login, ada token untuk mengubungkan antara firebase dengan aplikasi mobile yang sedang dijalankan  | Banner notifikasi sistem muncul pada status bar ketika aplikasi diminimalkan (ditekan tombol Home) saat pesan FCM diterima. | Halaman detail pengumuman (/pengumuman/:id) yang langsung terbuka setelah banner notifikasi diklik, menampilkan ID pengumuman, judul, dan isi pesan notifikasi lengkap. |


## AI Challenge 