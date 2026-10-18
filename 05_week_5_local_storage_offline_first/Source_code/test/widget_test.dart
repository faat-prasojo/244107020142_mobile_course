import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_5_local_storage_offline_first/data/local/note.dart';
import 'package:week_5_local_storage_offline_first/data/repositories/note_repository.dart';
import 'package:week_5_local_storage_offline_first/router.dart';
import 'package:week_5_local_storage_offline_first/widgets/note_tile.dart';

import 'fake_note_repository.dart';

void main() {
  group('NoteTile', () {
    Widget host(Note note) => MaterialApp(
          home: Scaffold(
            body: NoteTile(note: note, onTap: () {}, onDelete: () {}),
          ),
        );

    testWidgets('menampilkan badge saat dirty == true', (tester) async {
      await tester.pumpWidget(host(
        Note(title: 'Rapat', updatedAt: DateTime(2026, 10, 1), dirty: true),
      ));
      expect(find.text('Rapat'), findsOneWidget);
      expect(find.text('belum tersinkron'), findsOneWidget);
    });

    testWidgets('tanpa badge saat dirty == false', (tester) async {
      await tester.pumpWidget(host(
        Note(title: 'Rapat', updatedAt: DateTime(2026, 10, 1)),
      ));
      expect(find.text('belum tersinkron'), findsNothing);
    });
  });

  group('Route /note/:id', () {
    // homeBuilder diganti Text agar HomeShell (SQLite sungguhan) tidak dibangun.
    Future<void> openAt(
      WidgetTester tester,
      String location,
      FakeNoteRepository repo,
    ) async {
      final router = createRouter(
        initialLocation: location,
        homeBuilder: (_) => const Text('home'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    final repo = FakeNoteRepository(items: [
      Note(
        id: 1,
        title: 'Belanja',
        body: 'Susu dan telur',
        updatedAt: DateTime(2026, 10, 18, 9, 5),
        dirty: true,
      ),
    ]);

    testWidgets('membaca catatan dari repository', (tester) async {
      await openAt(tester, '/note/1', repo);
      expect(find.text('Belanja'), findsOneWidget);
      expect(find.text('Susu dan telur'), findsOneWidget);
      expect(find.text('belum tersinkron'), findsOneWidget);
      expect(find.textContaining('18/10/2026 09:05'), findsOneWidget);
    });

    testWidgets('id yang tidak ada menampilkan pesan, bukan crash',
        (tester) async {
      await openAt(tester, '/note/99', repo);
      expect(find.text('Catatan tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('id bukan angka menampilkan halaman tidak valid',
        (tester) async {
      await openAt(tester, '/note/abc', repo);
      expect(find.text('Alamat catatan tidak valid.'), findsOneWidget);
    });
  });
}
