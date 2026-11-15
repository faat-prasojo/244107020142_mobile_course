# Review Checklist - Week 8

Project yang direview: hasil Week 7 (Clean Architecture, feature-first), disalin ke folder ini. Folder Week 7 tidak diubah.

## 1. Audit riwayat Git

Hasil `git log --oneline -15`, `git branch -a`, `git status`:

| Temuan | Detail |
|---|---|
| Commit langsung ke `main` | Semua commit; hanya ada branch `main` (tanpa `develop`). |
| Pesan commit tidak jelas | `-`, `Update`, `feat : debugging`, `feat : week 6 - report completed` (3x berturut-turut). |
| Branch berumur panjang | Tidak ada, karena tidak ada branch lain. |
| File tak terlacak | `08_week_8_.../` belum di-commit (hasil kerja minggu ini). |

## 2. Tulis ulang pesan commit

| Sebelum | Sesudah | Alasan |
|---|---|---|
| `-` (`0159a20`) | `test(widget): perbaiki widget_test week 3 dan week 6` | Isi commit hanya mengubah 2 file `widget_test.dart`; pesan lama tidak memberi info apa pun. |
| `Update` (`8150a28`) | `docs(readme): perbarui README` | Perubahan hanya 1 baris di `README.md`; tipe dan scope harus terlihat. |
| `feat : debugging` (`d4f5ea1`) | `feat(week7): tambah project clean architecture + README` dan `chore(week7): tambah konfigurasi Android/iOS` | Satu commit memuat project lengkap dan konfigurasi platform; sebaiknya dipecah per perubahan logis. |

## 3. Pemeriksaan mesin

| Perintah | Sebelum | Sesudah |
|---|---|---|
| `dart format --set-exit-if-changed lib test` | 26 dari 39 file belum rapi | Bersih |
| `flutter analyze` | Bersih (di Week 7) | `No issues found!` (setelah format, 2 info `curly_braces_in_flow_control_structures` di `login_page.dart` diperbaiki) |
| `flutter test` | 24 test hijau | 26 test hijau (+2 test `UpdateNote`) |

Catatan: `dart format .` dari root project gagal di Windows karena path panjang di folder `build/`, jadi dipakai `dart format lib test`.

## 4. Sterilitas layer

Grep `Dio(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences.getInstance|jsonDecode|Repository(|import 'package:(flutter|dio|sqflite|firebase)` pada `lib/` hanya mengembalikan 0 hasil di `presentation`, `domain`, dan `core`.

## 5. Temuan review kode

| # | Level | Temuan | Status |
|---|---|---|---|
| 1 | Blocker (arsitektur) | Ada dua router: `lib/routes.dart` (dipakai `main.dart`) dan `lib/router/app_router.dart` (login + FCM + redirect auth). Keduanya mendefinisikan `AppRoutes`. `main.dart` tidak memakai `appRouterProvider` dan tidak memanggil `Firebase.initializeApp` (hanya ada di `push_service.dart`), sehingga alur login/FCM Week 6 tidak terhubung ke app. | Belum diperbaiki; perlu keputusan produk (apakah login wajib?) dan PR terpisah. |
| 2 | Saran (arsitektur) | `lib/auth`, `lib/pages`, `lib/messaging`, `lib/router` berada di luar struktur `features/`. | Backlog: pindahkan ke `features/auth` dan `features/announcement`. |
| 3 | Saran (test) | `UpdateNote` memvalidasi judul kosong tetapi belum punya test. | Diperbaiki: `test/update_note_test.dart`. |
| 4 | Saran (keterbacaan) | Judul app di `main.dart` masih `Clean Architecture Notes (Week 7)`. | Belum diubah (di luar lingkup review ini). |
| 5 | Style | 26 file belum diformat. | Diperbaiki dengan `dart format`; dijaga oleh CI. |

## 6. Kesiapan tengah semester

- [x] Struktur feature-first untuk `notes` dan `settings`, grep sterilitas 0 hasil.
- [x] `flutter analyze` bersih.
- [x] `flutter test` hijau (26 test).
- [x] `dart format` bersih, CI ditambahkan (`.github/workflows/ci.yml`).
- [ ] PR kecil + review sejawat: perlu dikerjakan bersama pasangan di GitHub.
- [ ] Temuan #1 dan #2 ditindaklanjuti.
