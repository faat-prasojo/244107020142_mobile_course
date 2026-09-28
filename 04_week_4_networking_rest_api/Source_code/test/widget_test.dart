import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_4_networking_rest_api/data/models/post.dart';
import 'package:week_4_networking_rest_api/data/providers/providers.dart';
import 'package:week_4_networking_rest_api/data/repositories/post_repository.dart';
import 'package:week_4_networking_rest_api/main.dart';

// Fake Post Repository untuk tes UI
class FakePostRepository extends PostRepository {
  FakePostRepository() : super(Dio());

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    return [
      const Post(
        userId: 1,
        id: 1,
        title: 'Test Post Title',
        body: 'Test post body text',
      ),
    ];
  }

  @override
  Future<Post> fetchPostById(int id) async {
    return const Post(
      userId: 1,
      id: 1,
      title: 'Test Post Title',
      body: 'Test post body text',
    );
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override postRepositoryProvider agar tidak melempar UnimplementedError
          postRepositoryProvider.overrideWithValue(FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );

    // Selesaikan frame render async
    await tester.pumpAndSettle();

    // Verifikasi bahwa aplikasi dan teks dummy berhasil ditampilkan
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('Test Post Title'), findsOneWidget);
  });
}