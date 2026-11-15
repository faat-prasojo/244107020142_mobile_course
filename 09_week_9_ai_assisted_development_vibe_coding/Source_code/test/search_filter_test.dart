import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/core/failures.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/entities/note.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/repositories/note_repository.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/usecases/search_notes.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/providers/notes_providers.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/providers/search_providers.dart';

class FakeNotesRepository implements NoteRepository {
  FakeNotesRepository(this.items);

  final List<Note> items;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: items, failure: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final notes = [
    Note(id: 1, title: 'Belanja Bulanan', updatedAt: DateTime(2026, 10, 1)),
    Note(
      id: 2,
      title: 'Tugas Mobile',
      body: 'Daftar belanja alat tulis',
      updatedAt: DateTime(2026, 10, 2),
    ),
    Note(id: 3, title: 'Rapat', updatedAt: DateTime(2026, 10, 3)),
  ];
  const searchNotes = SearchNotes();

  group('SearchNotes UseCase (Pure Domain)', () {
    test('filter abaikan huruf besar/kecil', () {
      expect(searchNotes(notes, 'BELANJA'), hasLength(2));
    });

    test('query dengan spasi di tepi tetap cocok', () {
      expect(searchNotes(notes, '  belanja  '), hasLength(2));
    });

    test('cocok pada isi catatan, bukan hanya judul', () {
      final result = searchNotes(notes, 'alat tulis');
      expect(result.map((n) => n.id), [2]);
    });

    test('query tak cocok kembalikan kosong', () {
      expect(searchNotes(notes, 'zzz-tak-ada'), isEmpty);
    });

    test('query kosong atau hanya spasi mengembalikan semua catatan', () {
      expect(searchNotes(notes, ''), hasLength(3));
      expect(searchNotes(notes, '   '), hasLength(3));
    });

    test('tidak mengubah daftar asli', () {
      searchNotes(notes, 'rapat');
      expect(notes, hasLength(3));
    });
  });

  group('filteredNotesProvider', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNotesRepository(notes)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('mengikuti perubahan query dan bisa dihapus', () async {
      final container = makeContainer();
      await container.read(notesProvider.future);

      expect(container.read(filteredNotesProvider).value, hasLength(3));

      container.read(searchQueryProvider.notifier).update('rapat');
      expect(container.read(filteredNotesProvider).value, hasLength(1));

      container.read(searchQueryProvider.notifier).update('zzz');
      expect(container.read(filteredNotesProvider).value, isEmpty);

      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(filteredNotesProvider).value, hasLength(3));
    });
  });
}
