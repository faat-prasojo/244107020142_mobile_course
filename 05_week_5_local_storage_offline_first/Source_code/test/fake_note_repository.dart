import 'package:week_5_local_storage_offline_first/data/local/note.dart';
import 'package:week_5_local_storage_offline_first/data/repositories/note_repository.dart';

/// Repository palsu: tidak menyentuh SQLite sama sekali.
/// openDb melempar UnimplementedError, jadi kalau ada method yang lupa
/// di-override, test langsung gagal dengan pesan yang jelas.
class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
      : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;
  final List<int> synced = [];

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<Note?> fetchNote(int id) async {
    if (throwError) throw Exception('db locked (simulasi)');
    for (final n in items) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;

  @override
  Future<List<Note>> fetchDirty() async =>
      items.where((n) => n.dirty).toList();

  @override
  Future<void> markSynced(Note sent) async => synced.add(sent.id!);
}
