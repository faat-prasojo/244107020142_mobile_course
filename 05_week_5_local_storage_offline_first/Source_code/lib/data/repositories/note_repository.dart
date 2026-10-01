import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb; // injeksi DB agar bisa di-fake di test

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true, // setiap perubahan lokal = belum tersinkron
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  // Tidak ada di codelab, padahal mini project meminta CRUD penuh.
  Future<void> updateNote({
    required int id,
    required String title,
    String body = '',
  }) async {
    final db = await _openDb();
    await db.update(
      'notes',
      {
        'title': title,
        'body': body,
        'updated_at': DateTime.now().toIso8601String(),
        'dirty': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  // Antrean FIFO: catatan paling lama diproses lebih dulu.
  Future<List<Note>> fetchDirty() async {
    final db = await _openDb();
    final rows =
        await db.query('notes', where: 'dirty = 1', orderBy: 'updated_at ASC');
    return rows.map(Note.fromMap).toList();
  }

  // Bersihkan HANYA jika baris belum berubah sejak di-upload.
  // Ini menutup race condition pada markAllSynced.
  Future<void> markSynced(Note sent) async {
    final db = await _openDb();
    await db.update(
      'notes',
      {'dirty': 0},
      where: 'id = ? AND updated_at = ?',
      whereArgs: [sent.id, sent.updatedAt.toIso8601String()],
    );
  }

  // Dipertahankan karena disebut di codelab; tidak dipakai syncNotes.
  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}

// Provider yang dipakai UI dan test (tidak ditulis di codelab).
// retry: null mencegah auto-retry Riverpod 3 sehingga error langsung final.
final noteRepositoryProvider =
    Provider<NoteRepository>((ref) => NoteRepository());

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
  retry: (retryCount, error) => null,
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
  retry: (retryCount, error) => null,
);