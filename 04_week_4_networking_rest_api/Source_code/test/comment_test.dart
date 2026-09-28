import 'package:flutter_test/flutter_test.dart';
// PERBAIKAN: Impor model Comment
import '../lib/data/models/comment.dart'; 
// Atau gunakan package import sesuai nama project Anda:
// import 'package:_04_week_4_networking_rest_api/data/models/comment.dart';

void main() {
  group('Comment Model Test', () {
    test('fromJson harus mengembalikan instance Comment dengan nilai default saat field hilang/null', () {
      final Map<String, dynamic> incompleteJson = {
        'id': 10,
        'name': 'John Doe',
      };

      final comment = Comment.fromJson(incompleteJson);

      expect(comment.id, equals(10));
      expect(comment.name, equals('John Doe'));
      expect(comment.postId, equals(0));
      expect(comment.email, equals(''));
      expect(comment.body, equals(''));
    });

    test('Edge Case: fromJson harus menangani objek JSON yang seluruh nilainya null/salah tipe', () {
      final Map<String, dynamic> corruptedJson = {
        'postId': null,
        'id': 'bukan_angka',
        'name': null,
        'email': 12345,
        'body': null,
      };

      final comment = Comment.fromJson(corruptedJson);

      expect(comment.postId, equals(0));
      expect(comment.id, equals(0));
      expect(comment.name, equals(''));
      expect(comment.email, equals(''));
      expect(comment.body, equals(''));
    });
  });
}