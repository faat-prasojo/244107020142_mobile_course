import 'package:campus_notify_ai/ai/ai_exception.dart';
import 'package:campus_notify_ai/ai/ai_key_store.dart';
import 'package:campus_notify_ai/ai/ai_models.dart';
import 'package:campus_notify_ai/ai/ai_providers.dart';
import 'package:campus_notify_ai/ai/ai_service.dart';
import 'package:campus_notify_ai/core/app_theme.dart';
import 'package:campus_notify_ai/pages/ai_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeKeyStore implements AiKeyStore {
  _FakeKeyStore(this.key);

  String? key;

  @override
  Future<void> deleteKey() async => key = null;

  @override
  Future<bool> hasKey() async => key != null && key!.isNotEmpty;

  @override
  Future<String?> readKey() async => key;

  @override
  Future<void> saveKey(String value) async => key = value;
}

class _FakeAiService extends AiService {
  _FakeAiService()
    : super(client: MockClient((_) async => http.Response('', 200)));

  Object? error;
  List<String> chunks = const [];

  @override
  Future<void> streamReply({
    required String apiKey,
    required List<AiTurn> history,
    required void Function(String chunk) onChunk,
    String? announcementContext,
  }) async {
    if (error != null) throw error!;
    for (final chunk in chunks) {
      onChunk(chunk);
    }
  }
}

Widget _app({required String? key, required AiService service}) {
  return ProviderScope(
    overrides: [
      aiKeyStoreProvider.overrideWithValue(_FakeKeyStore(key)),
      aiServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const AiChatPage()),
  );
}

void main() {
  testWidgets('menampilkan welcome dan banner saat API key belum diatur', (
    tester,
  ) async {
    await tester.pumpWidget(_app(key: null, service: _FakeAiService()));
    await tester.pumpAndSettle();

    expect(find.text('Halo, saya Campus Assistant'), findsOneWidget);
    expect(find.textContaining('API key belum diatur'), findsOneWidget);

    final cta = find.text('Atur API Key');
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(cta, findsOneWidget);
  });

  testWidgets('kirim tanpa API key menampilkan pesan dan input tetap ada', (
    tester,
  ) async {
    await tester.pumpWidget(_app(key: null, service: _FakeAiService()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump();

    expect(
      find.text('API key belum diatur. Atur di Pengaturan AI dulu.'),
      findsOneWidget,
    );
    expect(find.text('Halo'), findsOneWidget);
  });

  testWidgets('tombol kirim aktif hanya saat input berisi teks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(key: 'test-api-key-1234567890', service: _FakeAiService()),
    );
    await tester.pumpAndSettle();

    IconButton sendButton() =>
        tester.widget<IconButton>(find.byKey(const Key('send-button')));

    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.pump();

    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('suggestion mengirim pertanyaan dan menampilkan jawaban', (
    tester,
  ) async {
    final service = _FakeAiService()..chunks = ['Jawaban uji'];
    await tester.pumpWidget(
      _app(key: 'test-api-key-1234567890', service: service),
    );
    await tester.pumpAndSettle();

    final suggestion = find.text('Apa itu Campus Notify?');
    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    expect(find.text('Apa itu Campus Notify?'), findsWidgets);
    expect(find.text('Jawaban uji'), findsOneWidget);
  });

  testWidgets('error menampilkan tombol coba lagi lalu pulih', (tester) async {
    final service = _FakeAiService()..error = AiException.fromStatus(500);
    await tester.pumpWidget(
      _app(key: 'test-api-key-1234567890', service: service),
    );
    await tester.pumpAndSettle();

    final suggestion = find.text('Apa itu Campus Notify?');
    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);

    service
      ..error = null
      ..chunks = ['Pulih'];
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Pulih'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });
}
