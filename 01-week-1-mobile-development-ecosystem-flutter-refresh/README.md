# Tugas Praktikum Minggu 1: Profil Mahasiswa

**Nama:** Faatihurrizki Prasojo

**NIM:** 244107020142

## Kendala Setup yang Ditemui
Selama proses instalasi dan menjalankan aplikasi pertama kali, saya menemui dua kendala utama:
1. **Gradle Build timeout:** Terjadi error `Timeout waiting to lock build logic queue`. Solusinya adalah dengan menghentikan proses Gradle yang berjalan di latar belakang atau menghapus file `buildLogic.lock`.
2. **Android NDK Corrupt:** Muncul pesan error `NDK did not have a source.properties file`. Kendala ini diselesaikan dengan menghapus folder NDK versi tersebut di `%localappdata%\Android\sdk\ndk` agar sistem Flutter/Gradle mengunduh ulang file NDK yang utuh dan benar secara otomatis. Selain itu, diperlukan pengaturan "Install via USB" pada Developer Options HP Xiaomi agar aplikasi bisa diinstal.

## Refleksi

### 1. Kapan pengembangan *native* lebih direkomendasikan dibanding *cross-platform*?

* **Performa Menjadi Prioritas:** 
* **Eksplorasi Hardware Mendalam:** 
* **Adopsi Fitur OS Terbaru:** 
* **Efisiensi Penyimpanan:** 

### 2. Bagaimana perubahan *state* memengaruhi *widget tree* pada konsep UI deklaratif?
 tampilan layar adalah hasil proyeksi dari data yang ada. 
* **Prosesnya:** Berbeda dengan cara lama di mana kita harus mengubah elemen UI satu per satu secara manual, pada UI deklaratif, kita hanya perlu mengubah datanya (*state*). Saat *state* tersebut diperbarui, Flutter akan secara otomatis menyusun ulang (*rebuild*) struktur *widget tree* di latar belakang dan merender tampilan baru yang sesuai dengan data terkini tersebut.

### 3. Mengapa *commit* yang kecil dan berpesan jelas sangat penting untuk tim dan portofolio?
* **Untuk Kolaborasi Tim:** *commit* dengan cakupan yang kecil membuat proses *code review* menjadi jauh lebih mudah dan meminimalisir bentrok kode (*merge conflict*). Jika nantinya ditemukan masalah, tim bisa melacak dan membatalkan (*revert*) bagian tersebut dengan aman tanpa merusak fitur lain yang sudah selesai.
* **Untuk Nilai Portofolio:** Riwayat *commit* yang rapi dan deskriptif berfungsi sebagai etalase profesionalisme Anda. Rekruter akan melihat bahwa Anda bekerja secara sistematis, terorganisir, dan siap beradaptasi dengan standar industri.

## Screenshot Hasil
| Hasil Awal | Mini Assignment |
| :---: | :---: |
| <img src="./screenshot/hasil_profil.jpeg" width="400"> | <img src="./screenshot/mini_assignment.jpeg" width="400"> |
