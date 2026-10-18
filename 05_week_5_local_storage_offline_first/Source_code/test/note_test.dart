import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_5_local_storage_offline_first/data/local/note.dart';
import 'package:week_5_local_storage_offline_first/data/repositories/note_repository.dart';
import 'package:week_5_local_storage_offline_first/data/sync.dart';

import 'fake_note_repository.dart';

ProviderContainer containerWith(FakeNoteRepository repo) {
  final container = ProviderContainer(
    overrides: [noteRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Note mapping', () {
    test('fromMap aman terhadap field yang hilang', () {
      final note = Note.fromMap({'title': 'Belanja'});
      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
    });

    test('flag dirty bertahan pada serialisasi', () {
      final note = Note(
        title: 'a',
        updatedAt: DateTime(2026, 9, 18),
        dirty: true,
      );
      final restored = Note.fromMap(note.toMap());
      expect(restored.dirty, isTrue);
    });
  });

  group('notesProvider dengan repository palsu', () {
    test('sukses', () async {
      final container = containerWith(FakeNoteRepository(items: [
        Note(title: 'Tes', updatedAt: DateTime.now()),
      ]));
      final notes = await container.read(notesProvider.future);
      expect(notes.length, 1);
      expect(notes.first.title, 'Tes');
    });

    test('error', () async {
      final container = containerWith(FakeNoteRepository(throwError: true));
      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('noteByIdProvider (halaman detail)', () {
    final items = [
      Note(id: 1, title: 'Satu', updatedAt: DateTime(2026, 10, 1)),
      Note(id: 2, title: 'Dua', updatedAt: DateTime(2026, 10, 2), dirty: true),
    ];

    test('mengembalikan catatan sesuai id', () async {
      final container = containerWith(FakeNoteRepository(items: items));
      final note = await container.read(noteByIdProvider(2).future);
      expect(note?.title, 'Dua');
      expect(note?.dirty, isTrue);
    });

    test('mengembalikan null untuk id yang tidak ada', () async {
      final container = containerWith(FakeNoteRepository(items: items));
      expect(await container.read(noteByIdProvider(99).future), isNull);
    });
  });

  group('syncNotes', () {
    test('berhenti di item gagal, sisanya tetap dirty', () async {
      final repo = FakeNoteRepository(items: [
        for (var i = 1; i <= 3; i++)
          Note(
            id: i,
            title: 'n$i',
            updatedAt: DateTime(2026, 10, 1),
            dirty: true,
          ),
      ]);
      final count = await syncNotes(repo, upload: (n) async {
        if (n.id == 2) throw Exception('server error (simulasi)');
      });
      expect(count, 1);
      expect(repo.synced, [1]);
    });

    test('offline: tidak ada yang diproses', () async {
      final repo = FakeNoteRepository(items: [
        Note(id: 1, title: 'a', updatedAt: DateTime(2026, 10, 1), dirty: true),
      ]);
      expect(await syncNotes(repo, online: false), 0);
      expect(repo.synced, isEmpty);
    });
  });
}
