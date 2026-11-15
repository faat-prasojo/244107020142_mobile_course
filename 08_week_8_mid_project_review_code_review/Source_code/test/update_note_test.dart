import 'package:flutter_test/flutter_test.dart';
import 'package:week_8_mid_project_review_code_review/core/failures.dart';
import 'package:week_8_mid_project_review_code_review/features/notes/domain/entities/note.dart';
import 'package:week_8_mid_project_review_code_review/features/notes/domain/repositories/note_repository.dart';
import 'package:week_8_mid_project_review_code_review/features/notes/domain/usecases/update_note.dart';

class FakeUpdateNoteRepository implements NoteRepository {
  Note? updatedNote;

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) async {
    updatedNote = note;
    return (success: true, failure: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final note = Note(
    id: 1,
    title: 'Judul',
    body: '',
    updatedAt: DateTime(2026, 10, 12),
    dirty: true,
  );

  group('UpdateNote UseCase', () {
    test('Gagal validasi jika judul kosong', () async {
      final repo = FakeUpdateNoteRepository();
      final result = await UpdateNote(repo)(note.copyWith(title: '  '));

      expect(result.success, isFalse);
      expect(result.failure, isA<ValidationFailure>());
      expect(repo.updatedNote, isNull);
    });

    test('Berhasil memperbarui catatan dengan judul valid', () async {
      final repo = FakeUpdateNoteRepository();
      final result = await UpdateNote(repo)(note);

      expect(result.success, isTrue);
      expect(repo.updatedNote, note);
    });
  });
}
