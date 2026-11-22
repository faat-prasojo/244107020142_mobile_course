# Week 10 — AI Feature Integration

| Ringkasan | Keterangan |
|---|---|
| Topik | Integrasi AI Feature ke aplikasi Campus Notify |
| Fitur baru | AI Campus Assistant berbasis Google Gemini |
| Sumber project | Source Campus Notify Week 6 dipindahkan ke folder Week 10 yang awalnya masih scaffold kosong |
| Fitur lama | Autentikasi, FCM, dan pengumuman tetap dipertahankan |
| Perangkat uji | `24094RAD4G` / `XGAEX8EEG6SSCYNV`, Android 16 (API 36) |

---

## 1. Tujuan Pembelajaran

| No | Tujuan | Bukti di Dokumen Ini |
|---|---|---|
| 1 | Mengintegrasikan LLM API tanpa merusak fitur lama | Bagian 6, 7, dan 10 |
| 2 | Memakai endpoint, model, dan streaming sesuai dokumentasi Gemini API terbaru | Bagian 5.1 |
| 3 | Memisahkan komunikasi API dari UI lewat AI service dan Riverpod | Bagian 2 |
| 4 | Menyimpan API key di `flutter_secure_storage`, bukan di source/Git/log/screenshot | Bagian 6.1 |
| 5 | Menangani error dengan pesan ramah dan tombol coba lagi | Bagian 5.2 dan 8.2 |
| 6 | Membuat UI chat yang lengkap: welcome, saran, bubble, loading, streaming, keyboard, scroll | Bagian 3 dan 7 |
| 7 | Memperbarui tampilan aplikasi agar seluruh alur mencerminkan AI Campus Assistant | Bagian 9 |
| 8 | Menguji aplikasi di perangkat fisik dan mengambil screenshot ADB nyata | Bagian 7 |

---

## 2. Arsitektur dan Alur Integrasi AI

### 2.1 Layer aplikasi

| Layer | Komponen | Tanggung jawab |
|---|---|---|
| Presentation | `AiChatPage`, `AiSettingsPage`, `HomePage`, widget | Menampilkan state dan menerima input pengguna |
| State management | `AiChatController` (Riverpod `Notifier`) | Validasi, loading, error, streaming, retry |
| AI service | `AiService`, `AiConfig`, `AiKeyStore`, `AiException` | HTTP + parsing SSE, konfigurasi, key, pemetaan error |
| Provider eksternal | Google Gemini Interactions API, model `gemini-4-hydrogen` | Menghasilkan jawaban |

### 2.2 Alur satu pertanyaan

| Langkah | Aksi | Hasil |
|---|---|---|
| 1 | Pengguna mengetik atau memilih saran | Teks masuk ke `AiChatPage._send()` |
| 2 | Cek status API key | Belum ada → SnackBar, teks tetap di input |
| 3 | `AiChatController.send()` | Validasi kosong dan batas 500 karakter |
| 4 | `AiKeyStore.readKey()` | Key diambil dari secure storage |
| 5 | `AiService.streamReply()` | Request SSE dengan header `x-goog-api-key` |
| 6 | Event `step.delta` | Bubble AI diperbarui bertahap |
| 7a | Sukses | Status pesan `done` |
| 7b | Gagal | Bubble `error` + tombol **Coba lagi** |

### 2.3 Aturan utama

| Aturan | Penjelasan |
|---|---|
| Konfigurasi terpusat | Endpoint, model, prompt, batas input, dan timeout hanya di `lib/ai/ai_config.dart` |
| UI hanya menampilkan state | Validasi, loading, dan retry ada di controller, bukan di widget |
| Tidak ada key di kode | Key dibaca dari secure storage saat request; UI hanya menampilkan status |
| Jangan mengarang | AI diminta mengatakan tidak tahu jika informasinya tidak tersedia |

---

## 3. Struktur Proyek

| Path | Status | Fungsi |
|---|---|---|
| `README.md` | Ditambahkan/diperbarui | Laporan praktikum |
| `docs/ai-log.md` | Ditambahkan | Provider, prompt, output nyata, kendala |
| `screenshots/01`–`06` | Ditambahkan | Bukti dari perangkat fisik |
| `lib/main.dart` | Dipertahankan | Firebase init, tema, ProviderScope, router |
| `lib/firebase_options.dart` | Dipertahankan | Konfigurasi Firebase dari Week 6 |
| `lib/ai/ai_config.dart` | Baru | Endpoint, model, system prompt, batas, timeout |
| `lib/ai/ai_models.dart` | Baru | `AiTurn`, `ChatMessage`, status pesan |
| `lib/ai/ai_exception.dart` | Baru | Pemetaan error ke pesan pengguna |
| `lib/ai/ai_key_store.dart` | Baru | `flutter_secure_storage` |
| `lib/ai/ai_service.dart` | Baru | HTTP + parsing SSE |
| `lib/ai/ai_providers.dart` | Baru | Provider Riverpod |
| `lib/ai/ai_chat_controller.dart` | Baru | Notifier chat, streaming, retry |
| `lib/core/app_theme.dart` | Diubah | Tema visual aplikasi |
| `lib/router/app_router.dart` | Diubah | Rute `/assistant`, `/ai-settings`, redirect auth |
| `lib/auth/` | Dipertahankan | Login, daftar, `TokenStore` |
| `lib/messaging/push_service.dart` | Diubah | FCM + deep link, API deprecation diperbaiki |
| `lib/pages/home_page.dart` | Diubah | Dashboard dengan akses AI Assistant |
| `lib/pages/announcement_page.dart` | Diubah | UI baru + CTA AI |
| `lib/pages/ai_chat_page.dart` | Baru | Halaman chat AI |
| `lib/pages/ai_settings_page.dart` | Baru | Pengaturan API key |
| `test/ai_service_test.dart` | Baru | 11 test mock HTTP/SSE |
| `test/ai_chat_controller_test.dart` | Baru | 7 test controller |
| `test/ai_chat_page_test.dart` | Baru | 5 widget test |
| `test/push_and_auth_test.dart` | Dipertahankan | 8 test auth/FCM |

---

## 4. Teknologi yang Digunakan

| Komponen | Paket / Teknologi | Fungsi |
|---|---|---|
| Framework | Flutter 3.47.7 / Dart 3.13.5 | Antarmuka dan logika aplikasi |
| State management & DI | `flutter_riverpod ^3.4.3` | State chat, status key, dependency injection |
| Routing | `go_router ^18.1.1` | Navigasi path dan redirect autentikasi |
| HTTP client | `http ^1.5.0` | Request Gemini dan pembacaan SSE |
| Secure storage | `flutter_secure_storage ^11.2.0` | Menyimpan API key Gemini |
| Firebase | `firebase_core ^5.0.0`, `firebase_auth ^7.0.0`, `firebase_messaging ^17.0.0` | Autentikasi dan notifikasi |
| Testing & lint | `flutter_test`, `flutter_lints ^6.0.0` | Unit test, widget test, static analysis |

| Keputusan dependency | Keterangan |
|---|---|
| Tidak memakai SDK Gemini | `http` sudah cukup untuk SSE dan menjaga dependency tetap minimal |
| Model | `gemini-4-hydrogen` |

---

## 5. Praktikum 1: API, Prompt, dan AI Service

### 5.1 Konteks yang perlu ada di prompt

| Item | Nilai | Sumber |
|---|---|---|
| Endpoint | `https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse` | Dokumentasi Gemini API |
| Model | `gemini-4-hydrogen` | Daftar model resmi Gemini |
| Autentikasi | Header `x-goog-api-key` | Dokumentasi Gemini API |
| Streaming | SSE, event `step.delta` dengan `delta.type == text` | Dokumentasi Gemini API |
| Model lama | Tidak dipakai (`gemini-2.5-flash` sudah deprecated) | Dokumentasi resmi |
| System prompt | `Kamu adalah Campus Assistant...` (lengkap di bawah) | `lib/ai/ai_config.dart` |
| Konteks pengumuman | Opsional, maksimal 800 karakter, hanya jika relevan | `AiConfig.buildSystemInstruction()` |

| Baris system prompt | Isi |
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

### 5.2 Output AI dan keputusan

| Artefak | File | Keputusan |
|---|---|---|
| Konfigurasi API | `lib/ai/ai_config.dart` | Diterima; endpoint dan model diverifikasi ke dokumentasi resmi |
| AI service + SSE | `lib/ai/ai_service.dart` | Diterima; diuji dengan mock untuk sukses, 401, 429, 500, respons kosong |
| Controller chat | `lib/ai/ai_chat_controller.dart` | Diterima; ada test loading, error, retry, riwayat, `clear` |
| UI chat | `lib/pages/ai_chat_page.dart` | Diterima; bug tanpa key ditemukan lalu diperbaiki (Bagian 8.2) |
| Jawaban nyata | `screenshots/04-ai-assistant-response.png` | Diterima; berasal dari request sungguhan di perangkat |
| User prompt uji | `Apa itu Campus Notify  jelaskan singkat` | Diketik lewat ADB; jawaban lengkap di `docs/ai-log.md` |

---

## 6. Praktikum 2: Pemeriksaan Mesin dan Hasil Pengujian

### 6.1 Pemeriksaan kebocoran API key

| Pemeriksaan | Perintah / Cara | Hasil |
|---|---|---|
| String key di seluruh project | `grep -rn "PREFIX_API_KEY_ANDA" 244107020142_mobile_course/` | `No matches found` |
| Key di screenshot pengaturan | Cek visual `screenshots/05-ai-settings.png` | Hanya status "Aktif", nilai tidak tampil |
| Kondisi awal Week 10 | `flutter analyze` sebelum implementasi | 4 issue dari scaffold default |
| Kondisi awal Week 10 | `flutter test` sebelum implementasi | Gagal karena `main.dart`/`MyApp` belum ada |
| Kondisi akhir | Kedua masalah awal | Sudah diperbaiki |

### 6.2 Static analysis

| Perintah | Hasil terminal | Status |
|---|---|---|
| `flutter analyze` | `No issues found! (ran in 13.8s)` | PASS |

### 6.3 Unit test dan widget test

| Perintah | Hasil terminal | Status |
|---|---|---|
| `flutter test` | `00:03 +31: All tests passed!` | PASS |

| Keterangan test | Nilai |
|---|---|
| Total test | 31 |
| Request API nyata saat test | Tidak ada; memakai `MockClient` dan fake key store |
| API key di kode test | Tidak ada |

### 6.4 Rincian test

| File test | Jenis | Jumlah | Yang diuji |
|---|---|---|---|
| `ai_service_test.dart` | Unit (mock HTTP) | 11 | Request + chunk SSE, konteks pengumuman, key kosong, HTTP 401/429/500, respons tanpa teks, event error, kegagalan koneksi, validasi key |
| `ai_chat_controller_test.dart` | Unit (controller) | 7 | Pesan kosong, key belum ada, pesan terlalu panjang, streaming loading→selesai, error→retry, riwayat, `clear` |
| `ai_chat_page_test.dart` | Widget | 5 | Welcome + banner, SnackBar tanpa key, tombol kirim, suggestion, retry |
| `push_and_auth_test.dart` | Unit (Week 6) | 8 | `routeFromMessage` dan `maskToken` |

---

## 7. Bukti Tangkapan Layar (Screenshots)

| No | Skenario | File | Status |
|---|---|---|---|
| 1 | Dashboard setelah login | `screenshots/01-dashboard.png` | Diambil |
| 2 | Welcome AI Assistant tanpa API key | `screenshots/02-ai-assistant-welcome.png` | Diambil |
| 3 | Pesan terkirim + indikator loading | `screenshots/03-ai-assistant-chat.png` | Diambil |
| 4 | Jawaban Gemini, streaming selesai | `screenshots/04-ai-assistant-response.png` | Diambil |
| 5 | Pengaturan AI, key tersimpan (nilai tidak tampil) | `screenshots/05-ai-settings.png` | Diambil |
| 6 | Kirim tanpa API key → SnackBar | `screenshots/06-ai-error-handling.png` | Diambil |
| 7 | HTTP 401/403/429 nyata | — | Belum diuji; tidak ada key cadangan untuk memicu error |

| Ketentuan screenshot | Pemenuhan |
|---|---|
| Sumber | Perangkat fisik `24094RAD4G` / `XGAEX8EEG6SSCYNV`, Android 16 (API 36) |
| Metode | `adb screencap` + `adb pull` |
| Nilai API key terlihat | Tidak |
| Screenshot dipalsukan | Tidak |

---

## 8. Review Kode dan Dokumentasi AI

### 8.1 Verifikasi dokumentasi API

| Item | Hasil verifikasi |
|---|---|
| Endpoint | Sesuai dokumentasi Gemini API (`interactions?alt=sse`) |
| Model | `gemini-4-hydrogen` tercantum di daftar model resmi |
| Model lama | Tidak dipakai karena sudah deprecated |
| Tebakan endpoint/model | Tidak ada; semua diverifikasi ke dokumentasi |

### 8.2 Temuan dan status

| # | Level | Area | Temuan | Bukti | Status |
|---|---|---|---|---|---|
| 1 | Blocker | Kebenaran UI | Kirim tanpa API key menghilangkan teks dan tanpa feedback, karena error masuk ke `_InlineError` yang disembunyikan saat banner aktif | Dicoba langsung di perangkat | Diperbaiki; SnackBar ditambahkan, input tidak dikosongkan, test regresi ditambahkan |
| 2 | Saran | UX | Markdown `**tebal**` tampil mentah di bubble | `screenshots/04-ai-assistant-response.png` | Belum diperbaiki; butuh dependency renderer markdown |
| 3 | Saran | UX | Jawaban pertama baru muncul setelah belasan detik | Screenshot loading 4 detik setelah kirim masih menunggu | Dimitigasi dengan indikator "Sedang menyiapkan jawaban..." |
| 4 | Saran | Keamanan | API key sempat dibagikan di chat saat pengujian | Key sudah dihapus dari perangkat dan tidak ada di repo | Perlu aksi pengguna: rotasi key di Google AI Studio |

### 8.3 Checklist verifikasi

| Item | Standar | Hasil |
|---|---|---|
| Endpoint dan model | Terverifikasi dari dokumentasi resmi | PASS |
| Key tidak bocor | Tidak ada di source, README, Git, log, screenshot | PASS |
| Test membuktikan perilaku | Assertion spesifik, bukan sekadar tidak error | PASS |
| Test tanpa API nyata | Semua request memakai `MockClient` | PASS |
| Fitur lama | Auth, FCM, pengumuman masih berfungsi | PASS |
| `flutter analyze` | 0 issue | PASS |
| `flutter test` | Semua lulus | PASS |
| `flutter build apk --debug` | APK dihasilkan | PASS |

### 8.4 Keputusan yang diambil

| Keputusan | Alasan |
|---|---|
| Tidak memakai simulasi streaming | Jawaban berasal dari SSE sungguhan |
| Tidak membuat API key palsu | Key palsu hanya menghasilkan error buatan |
| Tidak menambah SDK Gemini | `http` cukup untuk SSE dan dependency tetap minimal |
| Tidak mengklaim integrasi database kampus | Konteks pengumuman FCM hanya opsional |
| Tidak menulis response contoh ke README | Output AI diambil dari layar perangkat dan disimpan di `docs/ai-log.md` |

---

## 9. Perubahan dari Week 6

| File / folder | Perubahan | Alasan |
|---|---|---|
| `lib/ai/` | Ditambahkan (7 file) | Service, konfigurasi, keamanan key, error, provider, controller |
| `lib/pages/ai_chat_page.dart` | Ditambahkan | Welcome, saran, bubble, loading, retry, keyboard handling |
| `lib/pages/ai_settings_page.dart` | Ditambahkan | Input, ganti, hapus API key, status konfigurasi |
| `lib/pages/home_page.dart` | Diubah | Dashboard dengan akses utama ke AI Assistant |
| `lib/pages/announcement_page.dart` | Diubah | Tampilan baru + CTA AI |
| `lib/core/app_theme.dart` | Diubah | Tema konsisten untuk seluruh halaman |
| `lib/router/app_router.dart` | Diubah | Rute `/assistant` dan `/ai-settings`; redirect auth dipertahankan |
| `lib/auth/login_page.dart` | Diubah | Branding AI + perbaikan lint |
| `lib/messaging/push_service.dart` | Diubah | `onTokenRefresh`/`getToken` → `onRegistered`/`register()` |
| `test/ai_service_test.dart` | Ditambahkan | 11 test mock HTTP/SSE |
| `test/ai_chat_controller_test.dart` | Ditambahkan | 7 test state dan retry |
| `test/ai_chat_page_test.dart` | Ditambahkan | 5 widget test termasuk bug tanpa key |
| `pubspec.yaml` | Diubah | Nama package `campus_notify_ai` dan dependency baru |
| `README.md`, `docs/ai-log.md`, `screenshots/` | Ditambahkan/diperbarui | Dokumentasi dan bukti pengujian |

---

## 10. Status Kesiapan Week 10

| Kriteria | Status |
|---|---|
| `flutter analyze` bersih | PASS — `No issues found!` |
| `flutter test` | PASS — 31 test |
| `flutter build apk --debug` | PASS — `app-debug.apk` |
| AI service dengan SSE | Selesai, diuji dengan mock |
| Jawaban AI nyata | Diterima di perangkat fisik |
| API key tersimpan aman | Secure storage, tidak tampil di UI/log |
| Error handling + coba lagi | Diuji lewat unit/widget test |
| Bug kirim tanpa API key | Diperbaiki + test regresi |
| Perangkat fisik Android 16 | Berhasil dijalankan |
| Screenshot ADB nyata | 6 file |
| Fitur lama | Auth, FCM, pengumuman masih berfungsi |

---

## 11. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Kebocoran API key | Secure storage, tidak di source/Git/log/screenshot; backend proxy untuk produksi |
| Biaya API | Input maksimal 500 karakter, tombol kirim nonaktif saat request, `max_output_tokens: 800` |
| Rate limit | HTTP 429 dipetakan ke pesan ramah dan tombol Coba lagi |
| Internet terputus | Pesan error khusus koneksi, timeout, streaming terputus, dengan retry |
| Respons AI tidak relevan | System prompt membatasi topik dan melarang mengarang informasi resmi |
| Kebocoran data pribadi | System prompt melarang data sensitif; pengguna diingatkan tidak mengirim data pribadi |

---

## 12. Refleksi Praktikum

### 12.1 Fitur AI yang diintegrasikan dan alasannya

| Pertanyaan | Jawaban |
|---|---|
| Fitur apa? | Chat Campus Assistant berbasis Gemini dengan streaming SSE |
| Mengapa? | Informasi kampus tersebar di beberapa kanal, sehingga percakapan lebih praktis daripada daftar pengumuman |
| Data kampus? | Hanya konteks pengumuman FCM terakhir yang opsional; tidak ada klaim terhubung ke database kampus |

### 12.2 Perlindungan privasi pengguna

| Aspek | Tindakan |
|---|---|
| Penyimpanan key | `flutter_secure_storage`, tidak ditulis di kode |
| Tampilan UI | Hanya status "Aktif", nilai key tidak ditampilkan lagi |
| Data sensitif | System prompt melarang AI meminta NIK, password, dan data pribadi lain |
| Produksi | Disarankan backend proxy agar key tidak berada di perangkat |

### 12.3 Fallback saat layanan AI error

| Kondisi | Fallback |
|---|---|
| Semua error | Pesan bahasa Indonesia ramah + tombol **Coba lagi** |
| Jawaban palsu | Tidak dibuat; aplikasi tidak berpura-pura mendapat jawaban AI |
| Key belum diatur | SnackBar, teks yang diketik tetap tersimpan di input |
| Hasil pengujian | Bug awal ditemukan di perangkat, diperbaiki, lalu diberi test regresi |

### 12.4 Pembelajaran UX fitur AI di mobile

| Pembelajaran | Bukti / catatan |
|---|---|
| Indikator loading wajib | Jawaban nyata membutuhkan belasan hingga puluhan detik sebelum teks pertama |
| Input tidak tertutup keyboard | Layout chat menyesuaikan saat keyboard muncul |
| Contoh pertanyaan membantu | Empat saran ditampilkan di welcome state |
| Markdown perlu dirender | `**tebal**` masih tampil mentah; menjadi catatan perbaikan |
| Disclaimer diperlukan | Welcome state mengingatkan pengguna agar memverifikasi info resmi |
