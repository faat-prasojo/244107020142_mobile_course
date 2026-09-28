import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/models/comment.dart';
import 'data/providers/comment_providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Week 4 - REST API Comments',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CommentListPage(postId: 1),
    );
  }
}

class CommentListPage extends ConsumerWidget {
  final int postId;

  const CommentListPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengamati state AsyncValue dari commentListProvider
    final commentsAsync = ref.watch(commentListProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments (Post ID: $postId)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Melakukan refresh data saat tombol refresh ditekan
              ref.invalidate(commentListProvider(postId));
            },
          ),
        ],
      ),
      body: commentsAsync.when(
        // 1. Tampilan saat data berhasil dimuat
        data: (comments) {
          if (comments.isEmpty) {
            return const Center(
              child: Text('Tidak ada komentar untuk postingan ini.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: comments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final Comment comment = comments[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(comment.id.toString()),
                ),
                title: Text(
                  comment.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      comment.email,
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(comment.body),
                  ],
                ),
              );
            },
          );
        },
        // 2. Tampilan saat terjadi Error
        error: (error, stackTrace) {
          return Center(
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
                    getFriendlyErrorMessage(error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      // Mencoba memuat ulang data saat terjadi error
                      ref.invalidate(commentListProvider(postId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        },
        // 3. Tampilan saat masih proses Loading
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}