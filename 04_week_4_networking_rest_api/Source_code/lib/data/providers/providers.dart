import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  throw UnimplementedError();
});

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPosts();
});

// Helper untuk membaca posts sekali
Future<List<Post>> readPostsOnce(ProviderContainer container) async {
  return container.read(postsProvider.future);
}

// Helper untuk membaca error secara aman tanpa mencederai listener container
Future<Object?> readPostsErrorOnce(ProviderContainer container) async {
  try {
    return await container.read(postRepositoryProvider).fetchPosts();
  } catch (e) {
    return e;
  }
}