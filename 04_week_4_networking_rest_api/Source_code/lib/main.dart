import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/models/post.dart';
import 'data/network_errors.dart';
import 'data/paged_posts.dart';
import 'data/providers/providers.dart';

// 1. Konfigurasi GoRouter (Rute Utama & Detail Post)
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PagedPostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        final post = state.extra as Post?;
        return PostDetailPage(postId: id, post: post);
      },
    ),
  ],
);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'REST API Posts',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// 2. Widget PostTile yang Diekstrak
class PostTile extends StatelessWidget {
  final Post post;

  const PostTile({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        context.push('/post/${post.id}', extra: post);
      },
    );
  }
}

// 3. Halaman List Post Berhalaman (PagedPostPage)
class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        ref.read(pagedPostsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    if (state.error != null && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posts Paged')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  friendlyErrorMessage(state.error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(pagedPostsProvider.notifier).loadFirstPage(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Posts Paged')),
      body: ListView.builder(
        controller: _controller,
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (!state.hasMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Semua data termuat.')),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = state.items[index];
          return PostTile(post: post);
        },
      ),
    );
  }
}

// 4. Halaman Detail Post (/post/:id)
class PostDetailPage extends ConsumerWidget {
  final int postId;
  final Post? post;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Jika objek post dikirim via extra GoRouter, langsung tampilkan
    if (post != null) {
      return _buildScaffold(post!);
    }

    // 2. Jika tidak ada extra, cari di list state paged
    final pagedState = ref.watch(pagedPostsProvider);
    final found = pagedState.items.where((p) => p.id == postId);
    if (found.isNotEmpty) {
      return _buildScaffold(found.first);
    }

    // 3. Menggunakan postDetailProvider dari providers.dart jika dibuka langsung via URL
    final postAsync = ref.watch(postDetailProvider(postId));

    return postAsync.when(
      data: (fetchedPost) => _buildScaffold(fetchedPost),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text('Detail Post #$postId')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(friendlyErrorMessage(err), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Detail Post #$postId')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildScaffold(Post postData) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Post #${postData.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              postData.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              postData.body,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}