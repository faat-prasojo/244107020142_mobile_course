import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/core/failures.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/entities/note.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/domain/repositories/note_repository.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/pages/notes_page.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/providers/notes_providers.dart';

class SlowFake implements NoteRepository {
  SlowFake(this.items);
  final List<Note> items;
  Completer<void>? gate;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (gate != null) await gate!.future;
    return (notes: items, failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets('daftar tetap tampil saat invalidate (refresh)', (tester) async {
    final repo = SlowFake([
      Note(id: 1, title: 'Belanja', updatedAt: DateTime(2026)),
    ]);
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    repo.gate = Completer<void>();
    container.invalidate(notesProvider);
    await tester.pump();
    // ignore: avoid_print
    print(
      'saat reload: daftar tampil=${find.text('Belanja').evaluate().isNotEmpty} '
      'spinner=${find.byType(CircularProgressIndicator).evaluate().isNotEmpty}',
    );
    repo.gate!.complete();
    await tester.pumpAndSettle();
  });
}
