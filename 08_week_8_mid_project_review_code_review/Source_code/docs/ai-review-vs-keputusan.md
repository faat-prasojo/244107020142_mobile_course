# AI Review vs Keputusan

Reviewer awal: Zed coding agent (Claude). Konteks: feature-first Clean Architecture, Riverpod, GoRouter, SQLite. Fokus: kebenaran, arsitektur, test.

## Prompt

```
Review project Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan temuan teratas + level (blocker/saran) + alasan + usulan perbaikan.
```

## Usulan vs keputusan

| # | Usulan AI | Bukti verifikasi | Keputusan | Alasan |
|---|---|---|---|---|
| 1 | Dua router terpisah dan `AppRoutes` ganda; `main.dart` tidak memakai alur login/FCM. | `grep "routes.dart\|app_router" lib`: `main.dart` hanya import `routes.dart`; `grep "Firebase.initializeApp" lib`: hanya di `push_service.dart`. | Diterima, ditunda | Benar, tetapi menyatukan router mengubah perilaku app (login jadi wajib), jadi dikerjakan di PR sendiri. |
| 2 | `UpdateNote` belum punya test. | `ls test`: tidak ada test untuk `UpdateNote`. | Diterima, diperbaiki | Ditambah `test/update_note_test.dart` (2 kasus: gagal validasi, sukses). `flutter test` hijau. |
| 3 | Ekstrak validasi judul `AddNote` dan `UpdateNote` ke fungsi bersama di `core/`. | Validasi hanya 1 kondisi di 2 tempat. | Ditolak | Duplikasi kecil dan baru 2 pemakai; abstraksi baru menambah file tanpa manfaat nyata. Ditinjau ulang bila ada use case ketiga. |
| 4 | Pindahkan `lib/auth`, `lib/pages`, `lib/messaging` ke `features/`. | Struktur folder `lib/`. | Diterima, backlog | Benar, tetapi perpindahan file banyak; dipisah agar PR tetap < 300 baris. |

## Bukti mesin

```
dart format --set-exit-if-changed lib test  -> bersih
flutter analyze                              -> No issues found!
flutter test                                 -> All tests passed! (26 test)
```

Prompt asli dan output mentah AI perlu disimpan sebelum demo; ringkasan di atas dibuat dari hasil review pada sesi ini.
