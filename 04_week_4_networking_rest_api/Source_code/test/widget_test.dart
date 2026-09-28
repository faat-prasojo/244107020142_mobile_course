import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week_4_networking_rest_api/data/models/comment.dart';
import 'package:week_4_networking_rest_api/data/providers/comment_providers.dart';
import 'package:week_4_networking_rest_api/data/repositories/comment_repository.dart';
import 'package:week_4_networking_rest_api/main.dart';

class MockCommentRepository implements CommentRepository {
  @override
  Future<List<Comment>> fetchComments(int postId) async {
    return [
      Comment(
        postId: postId,
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        body: 'Test comment body',
      ),
    ];
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            MockCommentRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
  });
}