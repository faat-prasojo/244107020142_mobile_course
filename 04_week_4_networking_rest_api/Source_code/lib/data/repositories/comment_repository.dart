import 'package:dio/dio.dart';
import '../models/comment.dart';

class CommentRepository {
  final Dio _dio;

  // Menerima dependency Dio melalui constructor
  CommentRepository(this._dio);

  // Method untuk mengambil daftar komentar berdasarkan postId
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      // Mengatur opsi timeout khusus untuk request ini selama 10 detik
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final data = response.data ?? [];

    // Mapping response data JSON menjadi List<Comment>
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}