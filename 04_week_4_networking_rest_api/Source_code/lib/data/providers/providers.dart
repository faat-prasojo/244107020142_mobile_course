import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

// 1. Inisialisasi postRepositoryProvider dengan Dio nyata dari api_client.dart
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dio = createDio();
  return PostRepository(dio);
});

// 2. FutureProvider untuk mengambil semua posts
final postsProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPosts();
});

// 3. FutureProvider.family untuk detail post berdasarkan ID
final postDetailProvider = FutureProvider.family<Post, int>((ref, id) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPostById(id);
});

Future<List<Post>> readPostsOnce(ProviderContainer container) async {
  return container.read(postsProvider.future);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) async {
  try {
    return await container.read(postRepositoryProvider).fetchPosts();
  } catch (e) {
    return e;
  }
}