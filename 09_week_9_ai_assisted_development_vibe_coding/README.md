# Week 9 — AI-Assisted Development & Vibe Coding

Praktikum Week 9 ini membahas cara memakai AI coding assistant untuk menambah fitur ke aplikasi `Clean Architecture Notes`. Aplikasinya tidak dibuat dari nol. Saya melanjutkan project dari Week 7 dan Week 8, lalu menambahkan fitur **Search Notes** dengan bantuan AI. Setiap hasil dari AI saya cek ulang lewat kode, analyze, dan test sebelum dipakai.

---

## 1. Tujuan Pembelajaran

- Memahami apa itu AI-Assisted Development dan vibe coding, dan bagaimana peran developer berubah dari penulis kode menjadi pengarah dan pemeriksa.
- Memakai AI coding assistant dengan hati-hati. Kode dari AI tidak langsung disalin begitu saja.
- Menulis prompt yang jelas dan menyertakan konteks project, supaya hasil AI sesuai dengan Clean Architecture, Riverpod, dan aturan lint Flutter.
- Memeriksa hasil AI secara sistematis: menjalankan test, membaca kode, dan membuktikan setiap temuan.
- Menambah fitur search (use case, provider, widget empty state) tanpa membuat domain layer bergantung pada Flutter atau database.
- Menulis unit test dan widget test untuk memastikan fitur hasil AI berjalan sesuai harapan.
- Menolak saran AI yang tidak terbukti atau melanggar arsitektur, dan menuliskan alasannya.

---

## 2. Arsitektur dan Alur Vibe Coding

Arsitektur aplikasi masih tiga layer seperti di Week 7, dan arah dependensinya tetap menuju Domain. Yang berbeda di Week 9 adalah cara saya bekerja bersama AI di sekitar kode tersebut.

```text
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│  (NotesPage, NoteDetailPage, Riverpod Providers, Widgets)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ bergantung pada (imports)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        DOMAIN LAYER                         │
│    (Note, NoteRepository interface, UseCases, Failures)     │
│                ★ THE CORE — PURE DART ★                    │
└──────────────────────────────▲──────────────────────────────┘
                               │ diimplementasikan oleh
┌──────────────────────────────┴──────────────────────────────┐
│                         DATA LAYER                          │
│   (NoteModel + toMap/fromMap, NoteRepositoryImpl, SQLite)   │
└─────────────────────────────────────────────────────────────┘
```

Alur yang saya ikuti setiap kali memakai AI:

```text
Menyusun prompt (konteks + batasan arsitektur)
        ↓
Membaca output AI (use case / provider / widget / test)
        ↓
Pemeriksaan manual  ───────────────────────────────┐
  ├─ Apakah dependency rule dilanggar?             │
  ├─ Apakah ada method atau API yang sudah lama?   │  Tolak / perbaiki
  ├─ Apakah test benar-benar menguji perilaku?     │◄──────────────────
  └─ Apakah ada edge case yang terlewat?           │
        ↓ Lolos                                    │
flutter analyze + flutter test  ───────────────────┘
        ↓ Hijau
Baru dimasukkan ke kode utama
```

### Aturan Utama

1. **Domain tetap bersih.** `SearchNotes` hanya memakai Dart murni. Tidak ada import `flutter`, `sqflite`, atau `firebase`.
2. **Provider hanya merakit state.** Logika filter ada di use case `SearchNotes`, bukan di provider.
3. **AI hanya reviewer pertama.** Keputusan akhir tetap di tangan saya, dan setiap saran harus dibuktikan lewat test atau pengecekan manual.
4. **Cek mesin dulu.** Sebelum menganggap tugas selesai, `dart format`, `flutter analyze`, dan `flutter test` harus lolos.

---

## 3. Struktur Proyek

```text
09_week_9_ai_assisted_development_vibe_coding/
├── README.md                                        # Laporan praktikum (file ini)
└── Source_code/
    ├── lib/
    │   ├── main.dart                                # Entry point, ProviderScope, dan tema
    │   ├── routes.dart                              # GoRouter (appRouter)
    │   ├── core/
    │   │   ├── failures.dart                        # Failure, ValidationFailure
    │   │   └── format.dart                          # formatDisplayDate, formatNoteSnippet
    │   ├── features/
    │   │   ├── notes/
    │   │   │   ├── domain/
    │   │   │   │   ├── entities/note.dart           # Entity domain (Pure Dart)
    │   │   │   │   ├── repositories/note_repository.dart
    │   │   │   │   └── usecases/
    │   │   │   │       ├── add_note.dart
    │   │   │   │       ├── delete_note.dart
    │   │   │   │       ├── get_notes.dart
    │   │   │   │       ├── search_notes.dart        # BARU Week 9 (hasil AI, sudah divalidasi)
    │   │   │   │       └── update_note.dart
    │   │   │   ├── data/
    │   │   │   │   ├── datasources/notes_database.dart
    │   │   │   │   ├── models/note_model.dart
    │   │   │   │   └── repositories/note_repository_impl.dart
    │   │   │   └── presentation/
    │   │   │       ├── pages/
    │   │   │       │   ├── notes_page.dart          # Diubah: search bar + filteredNotesProvider
    │   │   │       │   └── note_detail_page.dart
    │   │   │       ├── providers/
    │   │   │       │   ├── notes_providers.dart
    │   │   │       │   └── search_providers.dart    # BARU Week 9 (searchQueryProvider, filteredNotesProvider)
    │   │   │       └── widgets/
    │   │   │           ├── note_tile.dart
    │   │   │           └── notes_empty_state.dart   # BARU Week 9 (hasil AI, sudah divalidasi)
    │   │   └── settings/
    │   │       ├── domain/  …
    │   │       ├── data/    …
    │   │       └── presentation/ …
    │   ├── auth/                                    # Sisa Week 6
    │   ├── messaging/                               # Sisa Week 6
    │   ├── pages/                                   # Sisa Week 6
    │   └── router/app_router.dart                   # Sisa Week 6
    └── test/
        ├── add_note_test.dart
        ├── format_test.dart
        ├── get_notes_test.dart
        ├── notes_empty_state_test.dart              # BARU Week 9: widget test empty state
        ├── notes_page_search_test.dart              # BARU Week 9: widget test alur search
        ├── note_test.dart
        ├── push_and_auth_test.dart
        ├── search_filter_test.dart                  # BARU Week 9: unit test SearchNotes + filteredNotesProvider
        ├── settings_test.dart
        ├── tmp_refresh_test.dart                    # BARU Week 9: widget test perilaku refresh
        ├── update_note_test.dart
        └── widget_test.dart                         # Placeholder
```

---

## 4. Teknologi yang Digunakan

| Komponen | Paket / Teknologi | Fungsi di Aplikasi |
|---|---|---|
| Framework | Flutter SDK 3.x / Dart 3.x | Membangun antarmuka dan logika aplikasi. |
| State Management & DI | `flutter_riverpod ^3.4.3` | Menyimpan state sekaligus mengatur Dependency Injection. |
| Routing | `go_router ^18.1.1` | Navigasi berbasis path. |
| Relational Database | `sqflite ^2.4.5`, `sqflite_common_ffi_web ^1.2.0` | Menyimpan catatan secara lokal, di mobile maupun web. |
| Key-Value Storage | `shared_preferences ^2.5.6` | Menyimpan pengaturan tema dan riwayat pembukaan aplikasi. |
| Secure Storage | `flutter_secure_storage ^11.2.0` | Menyimpan token (sisa Week 6). |
| Firebase | `firebase_core`, `firebase_auth`, `firebase_messaging` | Autentikasi dan push notification (sisa Week 6). |
| Testing & Lint | `flutter_test`, `flutter_lints ^6.0.0` | Unit test, widget test, dan static analysis. |

> Project ini **tidak memakai Dio** dan tidak punya remote datasource. Semua data disimpan lokal dengan SQLite.

---

## 5. Praktikum 1: Menyusun Prompt untuk Flutter + Clean Architecture

### 1. Konteks yang Perlu Ada di Prompt

Supaya output AI bisa langsung dipakai, prompt saya selalu memuat empat hal:
- State management yang dipakai, yaitu Riverpod dengan `NotifierProvider` dan `Provider`.
- Arsitektur yang diminta: logika bisnis masuk ke use case domain, bukan langsung ke provider atau widget.
- Batasan yang tegas: domain harus Pure Dart dan tidak boleh mengimpor `flutter` atau `sqflite`.
- Bentuk output yang saya mau, yaitu kode lengkap beserta test-nya.

**Prompt yang saya pakai untuk fitur Search:**

```text
Saya punya Flutter project dengan Clean Architecture feature-first (domain / data / presentation).
State management: flutter_riverpod ^3.4.3 (NotifierProvider, Provider).

Tolong buat:
1. Domain use case `SearchNotes` — Pure Dart, tidak ada import flutter/sqflite.
   Input: List<Note> notes, String query. Output: List<Note> yang cocok (case-insensitive,
   trim, cocok di title atau body).
2. Provider di presentation: `searchQueryProvider` (NotifierProvider<String>) dan
   `filteredNotesProvider` (Provider<AsyncValue<List<Note>>>) yang menggabungkan
   notesProvider dengan SearchNotes.
3. Widget `NotesEmptyState` yang menampilkan dua kondisi: tanpa pencarian (ajakan
   "Buat Catatan Pertama") dan saat mencari (pesan "Tidak ada catatan yang cocok"
   + tombol "Hapus Pencarian").
4. Unit test untuk SearchNotes dan widget test untuk NotesEmptyState.

Jaga agar domain layer tidak mengimpor package Flutter apapun.
```

### 2. Output AI dan Keputusan Saya

AI menghasilkan empat artefak utama. Masing-masing saya periksa sebelum dipakai.

| Artefak | File | Keputusan |
|---|---|---|
| Use case `SearchNotes` | `lib/features/notes/domain/usecases/search_notes.dart` | ✓  Diterima. Pure Dart dan logika filternya benar. |
| Provider search | `lib/features/notes/presentation/providers/search_providers.dart` | ✓  Diterima setelah saya sesuaikan sedikit. |
| Widget `NotesEmptyState` | `lib/features/notes/presentation/widgets/notes_empty_state.dart` | ✓  Diterima. Kedua kondisinya sudah benar. |
| Unit dan widget test | `test/search_filter_test.dart`, `test/notes_empty_state_test.dart` | ✓  Diterima setelah saya tambahkan edge case. |

---

## 6. Praktikum 2: Pemeriksaan Mesin dan Hasil Pengujian

### 1. Pemeriksaan Sterilitas Domain

Saya memastikan `SearchNotes` tidak mengimpor Flutter atau package infrastruktur. Caranya dengan `grep` pada folder domain:

```bash
# Hasilnya harus 0
grep -rn "import 'package:flutter" lib/features/notes/domain/
grep -rn "import 'package:sqflite" lib/features/notes/domain/
grep -rn "import 'package:firebase" lib/features/notes/domain/
```

**Hasil:** `0 hasil`. Domain layer masih bersih dan berisi Pure Dart. ✓ 

### 2. Static Analysis (`flutter analyze`)

```bash
flutter analyze
```

**Hasil di terminal:**

```text
Analyzing Source_code...
No issues found!
```

### 3. Menjalankan Unit Test dan Widget Test (`flutter test`)

```bash
flutter test
```

**Hasil di terminal:**

```text
00:00 +0: test/add_note_test.dart: AddNote UseCase Test (Validation & Domain Logic) Gagal validasi jika judul kosong atau hanya spasi
00:00 +1: test/add_note_test.dart: AddNote UseCase Test (Validation & Domain Logic) Berhasil menyimpan catatan dengan judul valid
00:00 +2: test/format_test.dart: Core Pure Format & Route Parser Tests formatDisplayDate memformat DateTime ke format DD/MM/YYYY HH:mm
00:00 +3: test/format_test.dart: Core Pure Format & Route Parser Tests parseRouteId mengurai string angka dan menangani null/kosong/invalid
00:00 +4: test/format_test.dart: Core Pure Format & Route Parser Tests formatNoteSnippet memotong teks panjang dan membersihkan newline
00:00 +5: test/get_notes_test.dart: GetNotes UseCase Test (Pure Domain) GetNotes meneruskan daftar dari repository
00:00 +6: test/get_notes_test.dart: GetNotes UseCase Test (Pure Domain) GetNotes meneruskan failure tanpa melempar exception
00:01 +7: test/note_test.dart: NoteModel Data Layer Tests fromMap aman terhadap field yang hilang
00:01 +8: test/note_test.dart: NoteModel Data Layer Tests flag dirty bertahan pada serialisasi model
00:01 +9: test/note_test.dart: NoteModel Data Layer Tests toEntity menghasilkan domain entity murni
00:01 +10: test/note_test.dart: Presentation Provider DI Wiring Tests provider sukses dengan repository palsu disuntikkan
00:01 +11: test/note_test.dart: Presentation Provider DI Wiring Tests provider error menangkap Failure dan melempar Exception ramah UI
00:02 +12: test/notes_empty_state_test.dart: tanpa pencarian: tampil ajakan membuat catatan pertama
00:02 +13: test/notes_empty_state_test.dart: saat mencari: tampil pesan tidak cocok dan hapus pencarian
00:03 +14: test/notes_page_search_test.dart: mengetik query memfilter daftar, lalu empty state muncul
00:04 +15: test/notes_page_search_test.dart: kolom pencarian sinkron dengan query saat halaman dibuat ulang
00:05 +16: test/search_filter_test.dart: SearchNotes UseCase (Pure Domain) filter abaikan huruf besar/kecil
00:05 +17: test/search_filter_test.dart: SearchNotes UseCase (Pure Domain) query dengan spasi di tepi tetap cocok
00:05 +18: test/search_filter_test.dart: SearchNotes UseCase (Pure Domain) cocok pada isi catatan, bukan hanya judul
00:05 +19: test/search_filter_test.dart: SearchNotes UseCase (Pure Domain) query tak cocok kembalikan kosong
00:05 +20: test/search_filter_test.dart: SearchNotes UseCase (Pure Domain) query kosong atau hanya spasi mengembalikan semua catatan
00:05 +21: test/search_filter_test.dart: SearchNotes UseCase (Pure Domain) tidak mengubah daftar asli
00:05 +22: test/search_filter_test.dart: filteredNotesProvider mengikuti perubahan query dan bisa dihapus
00:08 +23: test/settings_test.dart: Settings Feature Domain Tests GetSettings mengembalikan entity AppSettings murni
00:08 +24: test/settings_test.dart: Settings Feature Domain Tests ToggleThemeMode mempertahankan mode lama saat repository gagal
00:08 +25..+26: test/push_and_auth_test.dart: routeFromMessage memakai data.route kalau ada di whitelist
00:08 +27: test/push_and_auth_test.dart: routeFromMessage fallback ke /announcement
00:08 +28: test/push_and_auth_test.dart: routeFromMessage menolak rute di luar whitelist
00:08 +29..+31: test/push_and_auth_test.dart: maskToken (null/kosong, token pendek, token panjang)
00:08 +32..+33: test/push_and_auth_test.dart: authErrorMessage (invalid-credential, kode tak dikenal)
00:08 +34: test/update_note_test.dart: UpdateNote UseCase Gagal validasi jika judul kosong
00:08 +35: test/update_note_test.dart: UpdateNote UseCase Berhasil memperbarui catatan
00:08 +36: test/tmp_refresh_test.dart: daftar tetap tampil saat invalidate (refresh)
00:08 +37: test/widget_test.dart: placeholder
00:08 +38: All tests passed!
```

Total ada **38 unit test dan widget test, dan semuanya lulus**. Dibanding Week 8 yang punya 26 test, ada tambahan 12 test dari fitur Search.

### 4. Rincian Test Baru Week 9

| File Test | Jenis | Jumlah | Yang Diuji |
|---|---|---|---|
| `search_filter_test.dart` | Unit test (domain murni) | 6 | `SearchNotes`: tidak peka huruf besar/kecil, trim spasi, mencari di isi body, hasil kosong, daftar asli tidak berubah, dan query kosong. |
| `search_filter_test.dart` | Unit test (provider) | 1 | `filteredNotesProvider` ikut berubah saat query berubah, lalu semua catatan muncul lagi setelah query dihapus. |
| `notes_empty_state_test.dart` | Widget test | 2 | Tanpa pencarian tampil ajakan membuat catatan, saat mencari tampil tombol "Hapus Pencarian". |
| `notes_page_search_test.dart` | Widget test | 2 | Mengetik query memfilter daftar, dan kolom pencarian tetap sinkron saat halaman dibangun ulang. |
| `tmp_refresh_test.dart` | Widget test | 1 | Daftar catatan tidak hilang saat `invalidate` (refresh) berjalan. |

---

## 7. Bukti Tangkapan Layar (Screenshots)

Folder `screenshots/` belum saya buat, jadi belum ada bukti visual untuk fitur Search. Berikut skenario yang perlu saya ambil gambarnya:

| Skenario | Query yang Dipakai | Hasil yang Diharapkan | Bukti |
|---|---|---|---|
| **1. Query cocok** | Salah satu kata di judul catatan | Daftar hanya menampilkan catatan yang cocok. | ⚠️ Belum diambil |
| **2. Query tidak cocok** | `zzz-tidak-ada` | Empty state dengan pesan pencarian dan tombol "Hapus Pencarian". | ⚠️ Belum diambil |
| **3. Query kosong** | (dihapus dengan tombol ✕) | Semua catatan kembali tampil. | ⚠️ Belum diambil |
| **4. Mode gelap** | Query cocok | Hasil pencarian tetap terbaca dengan tema gelap. | ⚠️ Belum diambil |
| **5. Output terminal** | — | Hasil `flutter analyze` dan `flutter test` bersih. | ⚠️ Belum diambil |

Setelah screenshot diambil, file-nya disimpan di folder `screenshots/` dan ditambahkan ke tabel di atas.

---

## 8. Review Kode dan Dokumentasi AI

### 1. Prompt Review

Setelah fitur search selesai, saya meminta AI mereview kodenya dengan prompt berikut:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation -> domain <- data),
Riverpod, SQLite. Fokus: kebenaran, arsitektur, test.
Abaikan style. Berikan 3 temuan teratas + level blocker/saran + alasan.
```

### 2. Temuan dan Statusnya

| # | Level | Area | Temuan | Bukti Verifikasi | Status |
|---|---|---|---|---|---|
| 1 | Saran | Kebenaran | Dialog tambah catatan memanggil `Navigator.pop` sebelum `failure` dicek, sehingga input hilang saat validasi gagal. | Saya cek langsung di kode `_showAddNoteDialog`. Temuan ini sama dengan temuan Week 8 #2. | ✓  Diperbaiki. `pop` dipindah setelah pengecekan hasil. |
| 2 | Saran | Arsitektur | Filter search harus berada di domain, bukan di widget. | Hasil `grep` pada `lib/features/notes/domain/` tidak menemukan impor eksternal. | ✓  Sudah sesuai. Logika filter ada di `SearchNotes`. |

### 3. Checklist Verifikasi AI

| Item | Standar Pemeriksaan | Hasil |
|---|---|---|
| **Dependency rule** | Domain tidak mengimpor Flutter, SQLite, atau Firebase. | ✓  Hasil `grep` di `lib/features/notes/domain/` adalah 0. |
| **Test membuktikan perilaku** | Setiap test punya `expect` yang bisa gagal, bukan sekadar "tidak error". | ✓  Semua 12 test baru punya assertion yang spesifik. |
| **Edge case tercakup** | Query kosong, hanya spasi, perbedaan huruf besar/kecil, dan kecocokan di body. | ✓  Enam unit test `SearchNotes` sudah mencakupnya. |
| **Widget test tidak memakai database asli** | UI test memakai repository palsu. | ✓  `FakeNotesRepository` dipakai di semua widget test. |
| **Minimal satu saran AI ditolak** | Penolakan disertai alasan tertulis. | ✓  Lihat tabel di bagian 8.4. |
| **`flutter analyze` bersih** | 0 issue. | ✓  `No issues found!` |

### 4. Saran AI yang Ditolak

| Saran AI | Keputusan | Alasan |
|---|---|---|
| Menambahkan debounce 300 ms pada `searchQueryProvider` dengan `Timer` di dalam `Notifier`. | **Ditolak** | `Timer` di dalam `Notifier` membuat state sulit diuji karena bergantung pada waktu nyata. Filter `SearchNotes` berjalan di memori dan sangat cepat, jadi debounce belum diperlukan. Kalau nanti dibutuhkan, debounce sebaiknya ditaruh di layer widget, bukan di domain. |
| Memakai `SearchDelegate` bawaan Material sebagai pengganti `TextField` manual. | **Ditolak (sementara)** | `SearchDelegate` mengambil alih routing dan state, sehingga bertabrakan dengan GoRouter yang sudah dipakai. `TextField` manual lebih mudah dikontrol dan lebih mudah diuji. |

---

## 9. Perubahan dari Week 8

| File / Folder | Perubahan | Alasan |
|---|---|---|
| `lib/features/notes/domain/usecases/search_notes.dart` | **Ditambahkan** (hasil AI, sudah divalidasi) | Use case baru untuk memfilter catatan berdasarkan judul dan isi. Ditulis dalam Pure Dart. |
| `lib/features/notes/presentation/providers/search_providers.dart` | **Ditambahkan** | Berisi `searchQueryProvider`, `searchNotesProvider`, dan `filteredNotesProvider`. |
| `lib/features/notes/presentation/widgets/notes_empty_state.dart` | **Ditambahkan** (hasil AI, sudah divalidasi) | Widget dengan dua kondisi: kosong tanpa pencarian dan tidak ada hasil pencarian. |
| `lib/features/notes/presentation/pages/notes_page.dart` | **Diubah** | Search bar ditambahkan, dan daftar catatan sekarang mengikuti `filteredNotesProvider`. Dialog tambah catatan juga diperbaiki: `Navigator.pop` dipindah setelah pengecekan hasil (temuan #2 Week 8). |
| `test/search_filter_test.dart` | **Ditambahkan** | 7 test: 6 unit test `SearchNotes` dan 1 test provider. |
| `test/notes_empty_state_test.dart` | **Ditambahkan** | 2 widget test untuk `NotesEmptyState`. |
| `test/notes_page_search_test.dart` | **Ditambahkan** | 2 widget test untuk alur search di `NotesPage`. |
| `test/tmp_refresh_test.dart` | **Ditambahkan** | 1 widget test untuk perilaku refresh. |

---

## 10. Status Kesiapan Week 9

| Kriteria | Status |
|---|---|
| `flutter analyze` bersih | ✓  `No issues found!` |
| `flutter test` lulus semua | ✓  38 test (bertambah 12 dari Week 8) |
| Use case `SearchNotes` (Pure Dart) | ✓  Selesai |
| `searchQueryProvider` dan `filteredNotesProvider` | ✓  Selesai |
| Widget `NotesEmptyState` (dua kondisi) | ✓  Selesai |
| Search bar terpasang di `NotesPage` | ✓  Selesai |
| Validasi hasil AI (prompt, review, penolakan saran) | ✓  Dua saran ditolak dengan alasan tertulis |
| Perbaikan bug Week 8 #2 (dialog menutup sebelum cek failure) | ✓  Selesai |
| Domain tetap bersih (grep 0 impor eksternal) | ✓  Terbukti |


## 12. Refleksi Praktikum

### 1. Apa bedanya vibe coding yang produktif dengan yang berbahaya?

Vibe coding yang produktif terjadi kalau saya sudah paham arsitektur yang dituju sebelum menulis prompt, lalu memeriksa setiap hasil AI dengan cara yang jelas: batas layer, test, dan analyze. Saya tetap jadi pengambil keputusan. AI membantu mempercepat kerangka awal, tetapi keputusan teknis, termasuk menolak saran, tetap saya yang tentukan.

Vibe coding yang berbahaya adalah ketika kode AI langsung disalin tanpa dipahami. Risikonya bertumpuk: bug tersembunyi ikut masuk, dependency rule bisa dilanggar tanpa sengaja (misalnya domain mengimpor SQLite), method yang sudah usang ikut terbawa, dan utang teknis menumpuk karena tidak ada test.

Contoh konkret di Week 9: prompt saya mewajibkan `SearchNotes` ditulis dalam Pure Dart, sehingga hasil AI langsung sesuai aturan. Hasil `grep` pada folder domain membuktikan tidak ada impor dari luar.

### 2. Kenapa prompt yang spesifik menghasilkan kode yang lebih baik?

Prompt yang menyebut `NotifierProvider`, Clean Architecture feature-first, dan batasan "domain harus Pure Dart" menghasilkan `SearchNotes` yang langsung sesuai arsitektur, tanpa perlu banyak revisi. Sebaliknya, prompt umum seperti "buat fitur pencarian di Flutter" cenderung menaruh logika filter langsung di widget dengan `setState`. Itu melanggar pemisahan tanggung jawab yang sudah saya bangun sejak Week 7.

### 3. Saran AI mana yang saya tolak, dan kenapa?

- **Debounce dengan `Timer` di `Notifier`:** Saya tolak karena membuat `Notifier` sulit diuji secara konsisten, karena test jadi bergantung pada waktu nyata. Filter `SearchNotes` cukup cepat untuk dijalankan di setiap ketikan.
- **`SearchDelegate` Material:** Saya tolak karena ikut mengatur navigasi, sehingga bertabrakan dengan GoRouter. `TextField` manual lebih mudah saya kendalikan dan lebih mudah diuji dengan `tester.enterText`.

### 4. Perbaikan konkret setelah memakai AI, dan dampaknya

- **Fitur Search selesai dalam satu sesi.** Dengan prompt yang jelas, kerangka `SearchNotes`, `search_providers.dart`, dan `NotesEmptyState` sudah jadi di putaran pertama. Waktu yang saya habiskan untuk validasi dan penyesuaian lebih sedikit dibanding menulis semuanya dari nol.
- **Bug Week 8 #2 ikut tertutup.** Saat meninjau dialog `_showAddNoteDialog`, AI mengingatkan bahwa `Navigator.pop` sebaiknya dipanggil setelah pengecekan hasil. Temuan ini sudah saya catat di Week 8 tetapi belum sempat diperbaiki.
- **12 test baru.** Test yang dibuat dengan bantuan AI mencakup edge case yang mungkin terlewat kalau saya menulisnya manual dalam waktu terbatas, misalnya query yang diawali atau diakhiri spasi, pencarian di isi body catatan, dan perilaku refresh saat loading.
