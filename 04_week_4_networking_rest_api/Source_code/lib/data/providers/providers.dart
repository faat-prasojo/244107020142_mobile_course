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