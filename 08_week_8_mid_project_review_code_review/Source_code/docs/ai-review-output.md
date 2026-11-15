# Output Review AI - Week 8

Reviewer: Zed coding agent (Claude). Objek: `08_week_8_mid_project_review_code_review/Source_code` (salinan Week 7).

## Prompt

```
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

## Catatan konteks

- Prompt menyebut **Dio**, tetapi project ini tidak memakai Dio (tidak ada di `pubspec.yaml`, tidak ada remote datasource). Review hanya mencakup SQLite dan Firebase.
- Kode yang direview dibaca langsung: `routes.dart`, `main.dart`, `router/app_router.dart`, `messaging/push_service.dart`, `auth/*`, dan seluruh `features/notes` (domain, data, presentation).
- Satu temuan (#4) diverifikasi dengan test sementara yang sudah dihapus. Temuan lain diverifikasi dengan membaca dan `grep`.

## Ringkasan

| # | Level | Area | Temuan |
|---|---|---|---|
| 1 | Blocker | Kebenaran / arsitektur | Auth + FCM Week 6 tidak terhubung ke app yang berjalan |
| 2 | Saran | Kebenaran | Dialog tambah catatan menutup dan menghapus input saat validasi gagal |
| 3 | Saran | Arsitektur | Provider presentation mengimpor data layer dan melewati use case |
| 4 | Saran | Kebenaran | `updateNote` / `deleteNote` melaporkan sukses untuk id yang tidak ada |
| 5 | Saran | Test | `NoteRepositoryImpl`, `DeleteNote`, dan UI tidak teruji |

---

## 1. Auth + FCM tidak terhubung ke app - **Blocker**

**Bukti**
- `lib/main.dart` hanya mengimpor `routes.dart` (`appRouter`), dan memanggil `markOpenedNow()` lalu `runApp`.
- `Firebase.initializeApp` hanya ada di `messaging/push_service.dart` (handler background). Tidak ada di `main()`.
- `routes.dart` dan `router/app_router.dart` sama-sama mendefinisikan `AppRoutes`. Hanya yang pertama yang dipakai app.
- `appRouterProvider`, `AuthController`, dan `PushService.start` hanya dipakai dari `HomePage`, `LoginPage`, dan `app_router.dart`, yaitu halaman yang hanya terjangkau lewat router yang tidak dipakai `main.dart`.

**Dampak**
Seluruh kode login, redirect auth, `TokenStore`, dan FCM tidak pernah berjalan. Test `push_and_auth_test.dart` hijau, tetapi hanya menguji fungsi murni. Jika `appRouterProvider` langsung dipasang tanpa inisialisasi Firebase, `FirebaseAuth.instance` akan melempar error saat `AuthController.build`.

**Usulan** (satu router, Firebase diinisialisasi sebelum `runApp`; perilaku login wajib perlu keputusan produk)

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  runApp(const ProviderScope(child: CleanNotesApp()));
}

// CleanNotesApp.build
final router = ref.watch(appRouterProvider);
return MaterialApp.router(routerConfig: router, scaffoldMessengerKey: scaffoldMessengerKey, ...);
```

Gabungkan rute `/note/:id` dan `/settings` dari `routes.dart` ke `app_router.dart`, lalu hapus `routes.dart`. Kerjakan di PR terpisah karena mengubah alur app.

---

## 2. Dialog tambah catatan menutup dan menghapus input saat gagal - **Saran**

**Bukti** (`notes_page.dart`, `_showAddNoteDialog`)
`Navigator.pop(ctx)` dipanggil sebelum pengecekan `result.failure`. Judul kosong membuat dialog tertutup, snackbar error muncul, dan teks body yang sudah diketik hilang. Selain itu `titleController` dan `bodyController` tidak pernah di-`dispose`.

**Usulan**

```dart
onPressed: () async {
  final result = await ref.read(addNoteProvider)(
    title: titleController.text,
    body: bodyController.text,
  );
  if (result.failure != null) {
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
    }
    return; // dialog tetap terbuka
  }
  if (ctx.mounted) Navigator.pop(ctx);
  ref.invalidate(notesProvider);
  ref.invalidate(dirtyCountProvider);
},
```

Dispose controller dengan `showDialog(...).whenComplete(() { titleController.dispose(); bodyController.dispose(); })`.

---

## 3. Provider presentation mengimpor data layer dan melewati use case - **Saran**

**Bukti** (`presentation/providers/notes_providers.dart`)
- Mengimpor `data/datasources/notes_database.dart` dan `data/repositories/note_repository_impl.dart`, padahal aturan README: presentation hanya bergantung pada domain.
- `dirtyCountProvider` dan `noteDetailProvider` memanggil `NoteRepository` langsung (`countDirty`, `getNoteById`), sedangkan operasi lain lewat use case. Pola tidak konsisten.
- Typo import: `'../..//data/datasources/notes_database.dart'` (double slash).

**Dampak**
Dependency rule bocor dan UI bergantung pada kontrak repository yang lebih lebar dari kebutuhan. Grep sterilitas di README lolos karena hanya mencari `Repository(`, bukan impor `data/`.

**Usulan** (minimal: dua use case, wiring pindah ke data layer)

```dart
// domain/usecases/get_note_by_id.dart
class GetNoteById {
  const GetNoteById(this._repository);
  final NoteRepository _repository;
  Future<({Note? note, Failure? failure})> call(int id) =>
      _repository.getNoteById(id);
}
```

```dart
// data/note_repository_provider.dart  (satu-satunya tempat yang tahu NoteRepositoryImpl)
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(openDb: openNotesDb),
);
```

Presentation lalu hanya mengimpor `noteRepositoryProvider` dan use case. Tambahkan juga `CountDirtyNotes` dengan pola yang sama. Cek aturan baru dengan:

```bash
rg "import '.*/data/" lib/features/*/presentation
```

---

## 4. `updateNote` dan `deleteNote` sukses untuk id yang tidak ada - **Saran**

**Bukti** (diverifikasi dengan test SQLite in-memory, sudah dihapus)

```
UPDATE success=true failure=null
DELETE success=true failure=null
```

untuk id `999` yang tidak ada. `db.update` dan `db.delete` mengembalikan jumlah baris terdampak, tetapi nilainya dibuang.

**Dampak**
UI menampilkan "berhasil diperbarui/dihapus" padahal tidak ada yang berubah (misalnya catatan sudah dihapus dari layar lain).

**Usulan** (`note_repository_impl.dart`)

```dart
final rows = await db.update(
  'notes',
  model.toMap(),
  where: 'id = ?',
  whereArgs: [note.id],
);
if (rows == 0) {
  return (
    success: false,
    failure: const LocalFailure('Catatan tidak ditemukan'),
  );
}
return (success: true, failure: null);
```

Terapkan pola yang sama pada `deleteNote`.

Catatan terkait: pesan error repository menyisipkan `$e` mentah (`'Gagal membaca catatan: $e'`) dan provider membungkusnya lagi dengan `Exception(...)`, sehingga UI menampilkan teks seperti `Exception: Gagal ...: DatabaseException(...)`. Sebaiknya log error asli dan tampilkan pesan ramah ke pengguna.

---

## 5. Celah test pada data layer dan UI - **Saran**

**Bukti**
- Tidak ada test yang menyentuh `NoteRepositoryImpl` (`grep NoteRepositoryImpl test` kosong), padahal di sinilah bug #4 berada.
- `DeleteNote` tidak punya test.
- `test/widget_test.dart` masih placeholder, jadi alur tambah/edit/hapus di UI tidak teruji (termasuk bug #2).
- `markAllSynced` tidak dipanggil dari `lib/` mana pun, sehingga flag `dirty` tidak pernah dibersihkan. Badge "N lokal (dirty)" selalu sama dengan jumlah catatan. Ini perlu keputusan: hapus fitur sampai ada sync, atau tambahkan use case dan test-nya.

**Usulan** (test repository dengan SQLite in-memory; `sqflite_common_ffi` saat ini hanya transitif, tambahkan ke `dev_dependencies`)

```dart
void main() {
  sqfliteFfiInit();

  late NoteRepositoryImpl repo;
  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, onCreate: createNotesTables),
    );
    repo = NoteRepositoryImpl(openDb: () async => db);
  });

  test('updateNote gagal untuk id yang tidak ada', () async {
    final r = await repo.updateNote(
      Note(id: 999, title: 'x', updatedAt: DateTime(2026)),
    );
    expect(r.success, isFalse);
    expect(r.failure, isA<LocalFailure>());
  });
}
```

`_createTables` di `notes_database.dart` saat ini private, jadi buka (rename tanpa underscore) agar test memakai skema yang sama dengan app.

---

## Keputusan yang perlu diambil

| # | Keputusan | Alasan |
|---|---|---|
| 1 | Apakah login wajib di app final? | Menentukan bentuk satu router dan urutan inisialisasi. |
| 3 | Tambah use case baru, atau terima provider memakai repository langsung? | Use case tipis menambah file; konsistensi vs kesederhanaan. |
| 5 | Hapus `markAllSynced` / `dirty` sampai ada sync? | Kode mati dan badge menyesatkan. |

Semua usulan di atas belum diterapkan; ini adalah output review, bukan perubahan kode.
