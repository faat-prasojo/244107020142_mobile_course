# Tugas Praktikum Minggu 1: Profil Mahasiswa

**Nama:** Faatihurrizki Prasojo

**NIM:** 244107020142

## Kendala Setup yang Ditemui
Selama proses instalasi dan menjalankan aplikasi pertama kali, saya menemui dua kendala utama:
1. **Gradle Build timeout:** Terjadi error `Timeout waiting to lock build logic queue`. Solusinya adalah dengan menghentikan proses Gradle yang berjalan di latar belakang atau menghapus file `buildLogic.lock`.
2. **Android NDK Corrupt:** Muncul pesan error `NDK did not have a source.properties file`. Kendala ini diselesaikan dengan menghapus folder NDK versi tersebut di `%localappdata%\Android\sdk\ndk` agar sistem Flutter/Gradle mengunduh ulang file NDK yang utuh dan benar secara otomatis. Selain itu, diperlukan pengaturan "Install via USB" pada Developer Options HP Xiaomi agar aplikasi bisa diinstal.

## Refleksi

### 1. Kapan pengembangan *native* lebih direkomendasikan dibanding *cross-platform*?
Pengembangan secara *native* (seperti memakai Kotlin untuk Android atau Swift untuk iOS) adalah pilihan terbaik ketika:
* **Performa Menjadi Prioritas:** Sangat krusial untuk aplikasi yang membutuhkan pemrosesan berat, seperti *game* dengan grafis tinggi atau aplikasi *rendering* video.
* **Eksplorasi Hardware Mendalam:** Ketika aplikasi perlu berinteraksi langsung dengan sensor tingkat lanjut, kamera kustom, atau teknologi AR/VR tanpa adanya latensi dari sistem perantara (*bridge*).
* **Adopsi Fitur OS Terbaru:** Jika aplikasi harus segera mendukung fitur-fitur sistem operasi terbaru (*day-one support*) tanpa perlu menunggu pembaruan dari pihak *framework cross-platform*.
* **Efisiensi Penyimpanan:** Aplikasi *native* umumnya menghasilkan ukuran *file* (APK/IPA) yang lebih ringan karena tidak perlu menanamkan *engine platform* tambahan di dalam aplikasinya.

### 2. Bagaimana perubahan *state* memengaruhi *widget tree* pada konsep UI deklaratif?
Dalam konsep UI deklaratif (seperti yang dipakai Flutter), tampilan layar adalah hasil proyeksi dari data (*state*) yang ada. 
* **Prosesnya:** Berbeda dengan cara lama di mana kita harus mengubah elemen UI satu per satu secara manual, pada UI deklaratif, kita hanya perlu mengubah datanya (*state*). Saat *state* tersebut diperbarui, Flutter akan secara otomatis menyusun ulang (*rebuild*) struktur *widget tree* di latar belakang dan merender tampilan baru yang sesuai dengan data terkini tersebut.

### 3. Mengapa *commit* yang kecil dan berpesan jelas sangat penting untuk tim dan portofolio?
* **Untuk Kolaborasi Tim:** *commit* dengan cakupan yang kecil (fokus pada satu perubahan) membuat proses *code review* menjadi jauh lebih mudah dan meminimalisir bentrok kode (*merge conflict*). Jika nantinya ditemukan masalah, tim bisa melacak dan membatalkan (*revert*) bagian tersebut dengan aman tanpa merusak fitur lain yang sudah selesai.
* **Untuk Nilai Portofolio:** Riwayat *commit* yang rapi dan deskriptif berfungsi sebagai etalase profesionalisme Anda. Rekruter akan melihat bahwa Anda bekerja secara sistematis, terorganisir, dan siap beradaptasi dengan standar industri.

## Screenshot Hasil
Hasil Awal
![Hasil Profil](./screenshot/hasil_profil.jpeg)

Mini Assignment
![Hasil Profil](./screenshot/mini_assignment.jpeg)
