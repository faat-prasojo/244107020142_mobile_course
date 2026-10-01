import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';
import '../data/sync.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(cachedPostsProvider);
    final offline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts (cache-first)'),
        actions: [
          if (offline) const Icon(Icons.cloud_off),
          IconButton(
            icon: const Icon(Icons.refresh),
            // Aman memakai invalidate di sini: dipicu user, bukan oleh provider sendiri.
            onPressed: () => ref.invalidate(cachedPostsProvider),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(friendlyErrorMessage(err), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(cachedPostsProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (posts) => posts.isEmpty
            ? const Center(child: Text('Belum ada data.'))
            : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  final post = posts[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${post.id}')),
                    title: Text(post.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(post.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  );
                },
              ),
      ),
    );
  }
}