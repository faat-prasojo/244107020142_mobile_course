# AI Log — Campus Notify AI Campus Assistant

## 1. AI Provider dan Endpoint

- Provider: Google Gemini API (Interactions API).
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse`
- Sumber verifikasi: https://ai.google.dev/gemini-api/docs/text-generation dan halaman daftar model https://ai.google.dev/gemini-api/docs/models
- Autentikasi: header `x-goog-api-key` (nilai key tidak dicatat di dokumen ini).
- Streaming: Server-Sent Events, dengan event `step.delta` berisi potongan teks.

## 2. Model

- Nama model: `gemini-4-hydrogen` (tercantum di daftar model resmi sebagai "Gemini 4 Hydrogen", context 1M token, max output 64K).
- Konfigurasi di kode: `lib/ai/ai_config.dart`, dengan `generation_config.max_output_tokens = 800`, `store = false`, dan `stream = true`.

## 3. System Prompt yang Digunakan

Teks berikut diambil langsung dari `AiConfig.systemPrompt`:

```
Kamu adalah Campus Assistant, asisten virtual aplikasi Campus Notify untuk mahasiswa.
Aturan:
- Jawab dalam Bahasa Indonesia yang ramah, jelas, dan ringkas.
- Prioritaskan jawaban singkat dan terstruktur (poin-poin bila perlu).
- Jangan mengarang jadwal, pengumuman, kebijakan, atau informasi resmi kampus.
- Jika informasi tidak tersedia atau belum dapat diverifikasi, katakan dengan jujur dan sarankan pengguna memeriksa kanal resmi kampus.
- Jangan meminta NIK, nomor telepon, alamat, password, API key, atau data pribadi sensitif.
- Jangan membocorkan informasi pengguna lain.
- Jika pertanyaan di luar topik kampus, arahkan kembali dengan sopan.
```

Jika ada pengumuman FCM terakhir di perangkat, teks pengumuman (dibatasi 800 karakter) ditambahkan ke system instruction dengan instruksi "gunakan hanya jika relevan, dan jangan menambahkan fakta lain". Pada pengujian ini tidak ada pengumuman FCM yang diterima, sehingga konteks tersebut tidak dikirim.

## 4. Contoh User Prompt

Prompt yang benar-benar dikirim dari perangkat (diketik lewat ADB, sehingga terdapat dua spasi di antara "Notify" dan "jelaskan"):

```
Apa itu Campus Notify  jelaskan singkat
```

Prompt uji untuk kasus tanpa API key (tidak dikirim ke API, hanya menguji feedback aplikasi):

```
Jadwal UTS semester ini
```

## 5. Output AI Awal yang Diperoleh

Output berikut diambil dari UI aplikasi saat request ke Gemini berhasil di perangkat `24094RAD4G`. Markdown ditampilkan apa adanya, sama seperti di layar.

```
Halo! **Campus Notify** adalah aplikasi yang dirancang untuk membantu mahasiswa mendapatkan informasi dan notifikasi seputar aktivitas kampus secara lebih praktis.

Secara singkat, tujuan utamanya meliputi:
- **Pembaruan Informasi:** Membantu mahasiswa tetap terhubung dengan pengumuman atau info penting kampus.
- **Asisten Virtual:** Menyediakan **Campus Assistant** (saya) untuk membantu menjawab pertanyaan seputar kebutuhan kampus dengan cepat.

Untuk informasi fitur spesifik atau panduan resmi yang berlaku di kampusmu, silakan cek langsung pada menu informasi di aplikasi atau kanal resmi kampus, ya. Ada yang ingin kamu tanyakan lagi?
```

Bukti: `screenshots/04-ai-assistant-response.png` (teks jawaban tampil bertahap, dan indikator loading berhenti setelah selesai).

Catatan: jawaban ini bersifat umum. Kalimat "Campus Notify adalah aplikasi ... membantu mahasiswa mendapatkan informasi dan notifikasi" sesuai dengan fungsi aplikasi, tetapi model tidak memiliki akses ke data kampus. Pengguna tetap perlu memverifikasi informasi resmi.

## 6. Catatan Pengujian

| Tanggal / Sesi | Skenario | Hasil |
|---|---|---|
| Sesi 1 | Login dan daftar di perangkat fisik | PASS. Dashboard tampil. |
| Sesi 1 | Buka AI Assistant tanpa API key | PASS. Welcome, banner "API key belum diatur", dan chip "Atur API Key" tampil. |
| Sesi 1 | Kirim pesan tanpa API key | GAGAL (bug). Teks hilang dan tidak ada feedback. Diperbaiki pada sesi 2. |
| Sesi 2 | Kirim pesan tanpa API key (setelah perbaikan) | PASS. SnackBar "API key belum diatur. Atur di Pengaturan AI dulu." tampil dan teks tetap ada di input. |
| Sesi 2 | Simpan API key di Pengaturan AI | PASS. Status "Aktif", key tidak ditampilkan. |
| Sesi 2 | Kirim pertanyaan dengan API key | PASS. Loading "Sedang menyiapkan jawaban..." lalu jawaban tampil. |
| Sesi 2 | Keyboard saat mengetik | PASS. Input tetap terlihat di atas keyboard. |
| Sesi 2 | Hapus API key | PASS. Status kembali "Belum diatur". |
| Unit test | Mock HTTP/SSE, controller, widget | PASS. 31 test lulus. Tidak ada request ke API nyata. |

Yang belum diuji dengan API nyata: HTTP 400, 401/403, 429, 500, timeout, dan koneksi terputus di tengah streaming. Perilaku ini hanya diverifikasi lewat mock. Key tidak dipalsukan untuk memicu error, karena itu akan menghasilkan respons palsu dan bukan pengujian yang valid.

## 7. Kendala Implementasi

1. **Teks hilang saat tanpa API key.** `AiChatController.send` mengembalikan error ke state, tetapi `_InlineError` disembunyikan saat banner key aktif, sehingga pengguna tidak mendapat feedback. Perbaikan: `_send` di `AiChatPage` mengecek status key, menampilkan SnackBar, dan tidak mengosongkan input.
2. **Markdown belum dirender.** Jawaban Gemini memuat `**tebal**` dan daftar `-`, dan tampil sebagai teks mentah. Belum diperbaiki karena menambah dependency render markdown di luar cakupan minimal.
3. **Latensi jawaban.** Pada pengujian, teks pertama baru muncul setelah lebih dari 16 detik (diamati dari screenshot loading), dan jawaban lengkap tampil dalam hitungan puluhan detik (tidak diukur secara presisi). Indikator loading dipertahankan agar pengguna tahu request sedang berjalan.
4. **Input ADB.** Karakter `?` dan spasi perlu di-escape saat mengetik lewat `adb shell input text`. Pertanyaan pada pengujian diketik tanpa tanda tanya.
5. **Penyimpanan API key dalam percakapan.** Key sempat dibagikan dalam chat. Disarankan agar key tersebut dirotasi (dibuat baru dan key lama dihapus) setelah praktikum selesai.

## 8. Keputusan Teknis

- **Gemini Interactions API dengan SSE.** Dipilih karena mendukung streaming native. Simulasi streaming tidak digunakan.
- **`http` tanpa SDK tambahan.** Cukup untuk SSE dan menjaga dependency tetap minimal.
- **`flutter_secure_storage` untuk key.** Key tidak disimpan di SharedPreferences atau file.
- **Konfigurasi terpusat di `AiConfig`.** Endpoint, model, prompt, batas input, dan timeout hanya ada di satu file.
- **Riverpod Notifier untuk chat.** Logika validasi, loading, error, dan retry berada di controller, sehingga UI hanya menampilkan state.
- **Konteks pengumuman sebagai opsi.** Pengumuman FCM dikirim sebagai konteks, bukan data kampus yang diklaim terintegrasi.
- **Test tanpa API nyata.** Test menggunakan `MockClient` dan fake key store agar tidak ada biaya dan tidak ada key di kode test.
