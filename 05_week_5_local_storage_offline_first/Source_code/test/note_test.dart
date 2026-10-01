import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_5_local_storage_offline_first/data/local/note.dart';
import 'package:week_5_local_storage_offline_first/data/repositories/note_repository.dart';
import 'package:week_5_local_storage_offline_first/data/sync.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const []})
      : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final List<int> synced = [];

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<List<Note>> fetchDirty() async =>
      items.where((n) => n.dirty).toList();

  @override
  Future<void> markSynced(Note sent) async => synced.add(sent.id!);
}

void main() {
  test('fromMap aman terhadap field yang hilang', () {
    final note = Note.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('flag dirty bertahan pada serialisasi', () {
    final note =
        Note(title: 'a', updatedAt: DateTime(2026, 10, 1), dirty: true);
    expect(Note.fromMap(note.toMap()).dirty, isTrue);
  });

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(overrides: [
      noteRepositoryProvider.overrideWithValue(
        FakeNoteRepository(items: [
          Note(title: 'Tes', updatedAt: DateTime.now()),
        ]),
      ),
    ]);
    addTearDown(container.dispose);
    final notes = await container.read(notesProvider.future);
    expect(notes.single.title, 'Tes');
  });

  test('syncNotes berhenti di item gagal, sisanya tetap dirty', () async {
    final repo = FakeNoteRepository(items: [
      for (var i = 1; i <= 3; i++)
        Note(id: i, title: 'n$i', updatedAt: DateTime(2026, 10, 1), dirty: true),
    ]);
    final count = await syncNotes(repo, upload: (n) async {
      if (n.id == 2) throw Exception('server error (simulasi)');
    });
    expect(count, 1);
    expect(repo.synced, [1]);
  });
}