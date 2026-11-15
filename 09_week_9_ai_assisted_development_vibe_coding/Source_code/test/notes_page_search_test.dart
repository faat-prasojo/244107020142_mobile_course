import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/core/failures.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/entities/note.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/repositories/note_repository.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/pages/notes_page.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/providers/notes_providers.dart';

class FakeNotesRepository implements NoteRepository {
  FakeNotesRepository(this.items);

  final List<Note> items;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: items, failure: null);

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: items.length, failure: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final notes = [
    Note(id: 1, title: 'Belanja Bulanan', updatedAt: DateTime(2026, 10, 1)),
    Note(id: 2, title: 'Rapat Dosen', updatedAt: DateTime(2026, 10, 2)),
  ];

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNotesRepository(notes)),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mengetik query memfilter daftar, lalu empty state muncul', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Rapat Dosen'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'RAPAT');
    await tester.pumpAndSettle();
    expect(find.text('Belanja Bulanan'), findsNothing);
    expect(find.text('Rapat Dosen'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-tak-ada');
    await tester.pumpAndSettle();
    expect(
      find.text('Tidak ada catatan yang cocok dengan pencarian.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hapus Pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Rapat Dosen'), findsOneWidget);
  });

  testWidgets(
    'kolom pencarian sinkron dengan query saat halaman dibuat ulang',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNotesRepository(notes)),
        ],
      );
      addTearDown(container.dispose);

      Future<void> pump(Widget home) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: home),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(const NotesPage());
      await tester.enterText(find.byType(TextField), 'rapat');
      await tester.pumpAndSettle();

      await pump(const SizedBox());
      await pump(const NotesPage());

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'rapat');
      expect(find.text('Rapat Dosen'), findsOneWidget);
      expect(find.text('Belanja Bulanan'), findsNothing);
    },
  );
}
