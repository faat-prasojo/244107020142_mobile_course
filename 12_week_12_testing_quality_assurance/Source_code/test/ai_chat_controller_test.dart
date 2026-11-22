import 'dart:async';

import 'package:campus_notify_ai/ai/ai_chat_controller.dart';
import 'package:campus_notify_ai/ai/ai_exception.dart';
import 'package:campus_notify_ai/ai/ai_key_store.dart';
import 'package:campus_notify_ai/ai/ai_models.dart';
import 'package:campus_notify_ai/ai/ai_providers.dart';
import 'package:campus_notify_ai/ai/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _apiKey = 'test-api-key-1234567890';

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
  int calls = 0;
  final List<List<AiTurn>> histories = [];

  @override
  Future<void> streamReply({
    required String apiKey,
    required List<AiTurn> history,
    required void Function(String chunk) onChunk,
    String? announcementContext,
  }) async {
    calls++;
    histories.add(history);
    if (error != null) throw error!;
    for (final chunk in chunks) {
      onChunk(chunk);
    }
  }
}

class _ControlledAiService extends AiService {
  _ControlledAiService()
    : super(client: MockClient((_) async => http.Response('', 200)));

  final completer = Completer<void>();

  @override
  Future<void> streamReply({
    required String apiKey,
    required List<AiTurn> history,
    required void Function(String chunk) onChunk,
    String? announcementContext,
  }) async {
    onChunk('Halo');
    await completer.future;
    onChunk('!');
  }
}

ProviderContainer _container({
  required String? key,
  required AiService service,
}) {
  final container = ProviderContainer(
    overrides: [
      aiKeyStoreProvider.overrideWithValue(_FakeKeyStore(key)),
      aiServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AiChatController', () {
    test('pesan kosong diabaikan', () async {
      final service = _FakeAiService();
      final container = _container(key: _apiKey, service: service);

      await container.read(aiChatControllerProvider.notifier).send('   ');

      final state = container.read(aiChatControllerProvider);
      expect(state.messages, isEmpty);
      expect(service.calls, 0);
    });

    test('API key belum diatur memberi feedback tanpa memanggil API', () async {
      final service = _FakeAiService();
      final container = _container(key: null, service: service);

      await container.read(aiChatControllerProvider.notifier).send('Halo');

      final state = container.read(aiChatControllerProvider);
      expect(state.messages, isEmpty);
      expect(state.errorMessage, contains('API key'));
      expect(service.calls, 0);
    });

    test('pesan terlalu panjang ditolak', () async {
      final service = _FakeAiService();
      final container = _container(key: _apiKey, service: service);

      await container.read(aiChatControllerProvider.notifier).send('a' * 501);

      final state = container.read(aiChatControllerProvider);
      expect(state.messages, isEmpty);
      expect(state.errorMessage, contains('terlalu panjang'));
      expect(service.calls, 0);
    });

    test('streaming menampilkan loading lalu jawaban selesai', () async {
      final service = _ControlledAiService();
      final container = _container(key: _apiKey, service: service);
      final controller = container.read(aiChatControllerProvider.notifier);

      final future = controller.send('Halo');
      await Future<void>.delayed(Duration.zero);

      var state = container.read(aiChatControllerProvider);
      expect(state.isSending, isTrue);
      expect(state.messages, hasLength(2));
      expect(state.messages.last.status, ChatMessageStatus.streaming);
      expect(state.messages.last.text, 'Halo');

      service.completer.complete();
      await future;

      state = container.read(aiChatControllerProvider);
      expect(state.isSending, isFalse);
      expect(state.messages.last.status, ChatMessageStatus.done);
      expect(state.messages.last.text, 'Halo!');
    });

    test('error request menghasilkan bubble error dan bisa retry', () async {
      final service = _FakeAiService();
      final container = _container(key: _apiKey, service: service);
      final controller = container.read(aiChatControllerProvider.notifier);

      service.error = AiException.fromStatus(429);
      await controller.send('Halo');

      var state = container.read(aiChatControllerProvider);
      expect(state.isSending, isFalse);
      expect(state.messages.last.status, ChatMessageStatus.error);
      expect(state.messages.last.text, contains('Batas permintaan'));

      service
        ..error = null
        ..chunks = ['Halo', ' kampus!'];
      await controller.retry();

      state = container.read(aiChatControllerProvider);
      expect(state.messages, hasLength(2));
      expect(state.messages.last.status, ChatMessageStatus.done);
      expect(state.messages.last.text, 'Halo kampus!');
      expect(service.calls, 2);
    });

    test('riwayat percakapan ikut dikirim pada request berikutnya', () async {
      final service = _FakeAiService()..chunks = ['Jawaban pertama'];
      final container = _container(key: _apiKey, service: service);
      final controller = container.read(aiChatControllerProvider.notifier);

      await controller.send('Pertanyaan pertama');
      await controller.send('Pertanyaan kedua');

      expect(service.histories.last, hasLength(3));
      expect(service.histories.last[0].text, 'Pertanyaan pertama');
      expect(service.histories.last[1].role, AiRole.model);
      expect(service.histories.last[2].text, 'Pertanyaan kedua');
    });

    test('clear mengosongkan percakapan', () async {
      final service = _FakeAiService()..chunks = ['Jawaban'];
      final container = _container(key: _apiKey, service: service);
      final controller = container.read(aiChatControllerProvider.notifier);

      await controller.send('Halo');
      controller.clear();

      final state = container.read(aiChatControllerProvider);
      expect(state.messages, isEmpty);
      expect(state.errorMessage, isNull);
    });
  });
}
