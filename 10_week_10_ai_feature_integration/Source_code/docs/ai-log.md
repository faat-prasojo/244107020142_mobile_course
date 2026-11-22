# AI Log — Campus Notify AI Campus Assistant

| Ringkasan | Keterangan |
|---|---|
| Provider | Google Gemini API (Interactions API) |
| Model | `gemini-4-hydrogen` |
| Streaming | Server-Sent Events, event `step.delta` |
| Sumber output | Permintaan nyata dari perangkat `24094RAD4G` |

---

## 1. AI Provider dan Endpoint

| Item | Nilai |
|---|---|
| Provider | Google Gemini API (Interactions API) |
| Endpoint | `https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse` |
| Sumber verifikasi format request | https://ai.google.dev/gemini-api/docs/text-generation |
| Sumber verifikasi model | https://ai.google.dev/gemini-api/docs/models |
| Autentikasi | Header `x-goog-api-key` |
| Cara streaming | SSE, potongan teks pada event `step.delta` |

---

## 2. Model

| Item | Nilai |
|---|---|
| Nama model | `gemini-4-hydrogen` |
| Nama resmi | Gemini 4 Hydrogen |
| Context window | 1M token (dokumentasi resmi) |
| Maksimal output model | 64K token (dokumentasi resmi) |
| Batas output di aplikasi | `max_output_tokens: 800` |
| Opsi lain | `store = false`, `stream = true` |
| Lokasi konfigurasi | `lib/ai/ai_config.dart` |

---

## 3. System Prompt yang Digunakan

| Baris | Isi |
|---|---|
| 1 | `Kamu adalah Campus Assistant, asisten virtual aplikasi Campus Notify untuk mahasiswa.` |
| 2 | `Aturan:` |
| 3 | `- Jawab dalam Bahasa Indonesia yang ramah, jelas, dan ringkas.` |
| 4 | `- Prioritaskan jawaban singkat dan terstruktur (poin-poin bila perlu).` |
| 5 | `- Jangan mengarang jadwal, pengumuman, kebijakan, atau informasi resmi kampus.` |
| 6 | `- Jika informasi tidak tersedia atau belum dapat diverifikasi, katakan dengan jujur dan sarankan pengguna memeriksa kanal resmi kampus.` |
| 7 | `- Jangan meminta NIK, nomor telepon, alamat, password, API key, atau data pribadi sensitif.` |
| 8 | `- Jangan membocorkan informasi pengguna lain.` |
| 9 | `- Jika pertanyaan di luar topik kampus, arahkan kembali dengan sopan.` |

| Konteks tambahan | Aturan |
|---|---|
| Sumber | Pengumuman FCM terakhir di perangkat |
| Batas panjang | 800 karakter |
| Instruksi tambahan | "Gunakan hanya jika relevan, dan jangan menambahkan fakta lain" |
| Sesi pengujian | Tidak ada pengumuman yang diterima, jadi konteks tidak dikirim |

---

## 4. Contoh User Prompt

| Skenario | Prompt | Dikirim ke API? |
|---|---|---|
| Uji jawaban nyata | `Apa itu Campus Notify  jelaskan singkat` | Ya |
| Uji tanpa API key | `Jadwal UTS semester ini` | Tidak; hanya menguji feedback aplikasi |

| Catatan input | Keterangan |
|---|---|
| Tanda tanya | Tidak diketik karena perlu escape lewat `adb shell input text` |
| Spasi ganda | Hasil escape `%s` saat mengetik lewat ADB; teks dikirim apa adanya |

---

## 5. Output AI Awal yang Diperoleh

| Item | Keterangan |
|---|---|
| Sumber | UI aplikasi di perangkat `24094RAD4G` |
| Request | Berhasil |
| Model | `gemini-4-hydrogen` |
| Bukti | `screenshots/04-ai-assistant-response.png` |
| Penyajian | Teks di bawah sama persis dengan tampilan di layar, termasuk markdown mentah |

| Baris | Output AI |
|---|---|
| 1 | `Halo! **Campus Notify** adalah aplikasi yang dirancang untuk membantu mahasiswa mendapatkan informasi dan notifikasi seputar aktivitas kampus secara lebih praktis.` |
| 2 | (kosong) |
| 3 | `Secara singkat, tujuan utamanya meliputi:` |
| 4 | `- **Pembaruan Informasi:** Membantu mahasiswa tetap terhubung dengan pengumuman atau info penting kampus.` |
| 5 | `- **Asisten Virtual:** Menyediakan **Campus Assistant** (saya) untuk membantu menjawab pertanyaan seputar kebutuhan kampus dengan cepat.` |
| 6 | (kosong) |
| 7 | `Untuk informasi fitur spesifik atau panduan resmi yang berlaku di kampusmu, silakan cek langsung pada menu informasi di aplikasi atau kanal resmi kampus, ya. Ada yang ingin kamu tanyakan lagi?` |

| Penilaian | Keterangan |
|---|---|
| Kesesuaian | Jawaban bersifat umum dan tidak mengklaim data kampus tertentu |
| Markup | `**` tampil mentah karena belum ada renderer markdown |
| Verifikasi pengguna | Tetap diperlukan untuk informasi resmi |

---

## 6. Catatan Pengujian

| Sesi | Skenario | Hasil |
|---|---|---|
| 1 | Login dan daftar di perangkat fisik | PASS; dashboard tampil |
| 1 | Buka AI Assistant tanpa API key | PASS; welcome, banner, dan chip "Atur API Key" tampil |
| 1 | Kirim pesan tanpa API key | Gagal; teks hilang dan tidak ada feedback |
| 2 | Kirim tanpa key setelah perbaikan | PASS; SnackBar tampil dan teks tetap di input |
| 2 | Simpan API key di Pengaturan AI | PASS; status "Aktif", key tidak ditampilkan |
| 2 | Kirim pertanyaan dengan API key | PASS; loading lalu jawaban tampil |
| 2 | Keyboard saat mengetik | PASS; input tetap terlihat |
| 2 | Hapus API key | PASS; status kembali "Belum diatur" |
| Unit test | Mock HTTP/SSE, controller, widget | PASS; 31 test lulus, tanpa request API nyata |

| Yang belum diuji dengan API nyata | Alasan |
|---|---|
| HTTP 400, 401/403, 429, 500 | Tidak ada key cadangan untuk memicu error secara sah |
| Timeout dan streaming terputus | Tidak dipicu; hanya diuji lewat mock |
| API key palsu | Tidak dipakai karena akan menghasilkan respons buatan |

---

## 7. Kendala Implementasi

| # | Kendala | Penanganan / Status |
|---|---|---|
| 1 | Kirim tanpa API key menghilangkan teks dan tanpa feedback | Diperbaiki dengan SnackBar; input tidak dikosongkan; test widget ditambahkan |
| 2 | Markdown `**tebal**` tampil mentah | Belum diperbaiki; butuh dependency renderer markdown |
| 3 | Jawaban pertama baru muncul setelah 16 detik lebih | Dimitigasi dengan indikator "Sedang menyiapkan jawaban..." |
| 4 | Karakter `?` dan spasi perlu escape di ADB | Pertanyaan uji diketik tanpa tanda tanya |
| 5 | API key sempat dibagikan di chat | Disarankan rotasi key di Google AI Studio; key sudah dihapus dari perangkat |

---

## 8. Keputusan Teknis

| Keputusan | Alasan |
|---|---|
| Gemini Interactions API dengan SSE | Mendukung streaming native; tidak ada simulasi streaming |
| `http` tanpa SDK tambahan | Cukup untuk SSE dan menjaga dependency minimal |
| `flutter_secure_storage` untuk key | Key tidak disimpan di SharedPreferences atau file biasa |
| Konfigurasi terpusat di `AiConfig` | Endpoint, model, prompt, batas, dan timeout hanya di satu file |
| Riverpod `Notifier` untuk chat | UI hanya menampilkan state; validasi dan retry ada di controller |
| Konteks pengumuman sebagai opsi | Tidak mengklaim integrasi database kampus |
| Test dengan `MockClient` | Tidak ada biaya API dan tidak ada key di kode test |
