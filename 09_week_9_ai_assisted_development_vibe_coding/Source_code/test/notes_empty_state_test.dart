import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_9_ai_assisted_development_vibe_coding/features/notes/presentation/widgets/notes_empty_state.dart';

Widget _wrap({
  required bool isSearching,
  VoidCallback? onCreate,
  VoidCallback? onClearSearch,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NotesEmptyState(
        isSearching: isSearching,
        onCreate: onCreate ?? () {},
        onClearSearch: onClearSearch ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('tanpa pencarian: tampil ajakan membuat catatan pertama', (
    tester,
  ) async {
    var created = false;
    await tester.pumpWidget(
      _wrap(isSearching: false, onCreate: () => created = true),
    );

    expect(find.text('Belum ada catatan bisnis.'), findsOneWidget);
    expect(find.text('Hapus Pencarian'), findsNothing);

    await tester.tap(find.text('Buat Catatan Pertama'));
    expect(created, isTrue);
  });

  testWidgets('saat mencari: tampil pesan tidak cocok dan hapus pencarian', (
    tester,
  ) async {
    var cleared = false;
    await tester.pumpWidget(
      _wrap(isSearching: true, onClearSearch: () => cleared = true),
    );

    expect(
      find.text('Tidak ada catatan yang cocok dengan pencarian.'),
      findsOneWidget,
    );
    expect(find.text('Buat Catatan Pertama'), findsNothing);

    await tester.tap(find.text('Hapus Pencarian'));
    expect(cleared, isTrue);
  });
}
