import 'dart:convert';

import 'package:campus_notify_ai/ai/ai_config.dart';
import 'package:campus_notify_ai/ai/ai_exception.dart';
import 'package:campus_notify_ai/ai/ai_models.dart';
import 'package:campus_notify_ai/ai/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _apiKey = 'test-api-key-1234567890';

http.Response _sse(String text) {
  final payload = {
    'index': 0,
    'delta': {'type': 'text', 'text': text},
    'event_type': 'step.delta',
  };
  return http.Response(
    'event: step.delta\ndata: ${jsonEncode(payload)}\n\n'
    'event: done\ndata: [DONE]\n\n',
    200,
    headers: {'content-type': 'text/event-stream'},
  );
}

void main() {
  group('AiService.streamReply', () {
    test('mengirim request yang benar dan menggabungkan chunk', () async {
      late http.Request captured;
      final service = AiService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            'data: ${jsonEncode({
              'event_type': 'step.delta',
              'delta': {'type': 'text', 'text': 'Halo'},
            })}\n\n'
            'data: ${jsonEncode({
              'event_type': 'step.delta',
              'delta': {'type': 'text', 'text': ' kampus!'},
            })}\n\n',
            200,
          );
        }),
      );

      final chunks = <String>[];
      await service.streamReply(
        apiKey: _apiKey,
        history: const [
          AiTurn(role: AiRole.user, text: 'Apa itu Campus Notify?'),
        ],
        onChunk: chunks.add,
      );

      expect(chunks.join(), 'Halo kampus!');
      expect(captured.method, 'POST');
      expect(captured.url.toString(), AiConfig.endpoint);
      expect(captured.headers['x-goog-api-key'], _apiKey);
      expect(captured.headers['accept'], 'text/event-stream');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], AiConfig.model);
      expect(body['stream'], true);
      expect(body['store'], false);
      expect(body['system_instruction'], contains('Campus Assistant'));
      final input = body['input'] as List;
      expect(input.first['type'], 'user_input');
      expect(input.first['content'][0]['text'], 'Apa itu Campus Notify?');
    });

    test('meneruskan konteks pengumuman ke system instruction', () async {
      late http.Request captured;
      final service = AiService(
        client: MockClient((request) async {
          captured = request;
          return _sse('Siap');
        }),
      );

      await service.streamReply(
        apiKey: _apiKey,
        history: const [AiTurn(role: AiRole.user, text: 'Pengumuman?')],
        announcementContext: 'Judul: UTS\nIsi: UTS dimulai Senin.',
        onChunk: (_) {},
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['system_instruction'], contains('UTS dimulai Senin'));
    });

    test('API key kosong ditolak tanpa request', () async {
      var called = false;
      final service = AiService(
        client: MockClient((_) async {
          called = true;
          return _sse('x');
        }),
      );

      await expectLater(
        service.streamReply(
          apiKey: '   ',
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(
          isA<AiException>().having(
            (error) => error.kind,
            'kind',
            AiErrorKind.missingKey,
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('HTTP 401 menjadi pesan API key tidak valid', () async {
      final service = AiService(
        client: MockClient(
          (_) async =>
              http.Response('{"error":{"message":"API key not valid"}}', 401),
        ),
      );

      await expectLater(
        service.streamReply(
          apiKey: _apiKey,
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(
          isA<AiException>()
              .having((error) => error.kind, 'kind', AiErrorKind.invalidKey)
              .having(
                (error) => error.message,
                'message',
                isNot(contains('API key not valid')),
              ),
        ),
      );
    });

    test('HTTP 429 menjadi pesan rate limit', () async {
      final service = AiService(
        client: MockClient((_) async => http.Response('{}', 429)),
      );

      await expectLater(
        service.streamReply(
          apiKey: _apiKey,
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(
          isA<AiException>().having(
            (error) => error.kind,
            'kind',
            AiErrorKind.rateLimit,
          ),
        ),
      );
    });

    test('HTTP 500 menjadi pesan server', () async {
      final service = AiService(
        client: MockClient((_) async => http.Response('oops', 500)),
      );

      await expectLater(
        service.streamReply(
          apiKey: _apiKey,
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(
          isA<AiException>().having(
            (error) => error.kind,
            'kind',
            AiErrorKind.server,
          ),
        ),
      );
    });

    test('response tanpa teks dianggap kosong', () async {
      final service = AiService(
        client: MockClient((_) async => http.Response('data: [DONE]\n\n', 200)),
      );

      await expectLater(
        service.streamReply(
          apiKey: _apiKey,
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(
          isA<AiException>().having(
            (error) => error.kind,
            'kind',
            AiErrorKind.emptyResponse,
          ),
        ),
      );
    });

    test('error event dari provider diteruskan sebagai AiException', () async {
      final service = AiService(
        client: MockClient(
          (_) async => http.Response(
            'data: ${jsonEncode({
              'error': {'message': 'blocked'},
              'event_type': 'error',
            })}\n\n',
            200,
          ),
        ),
      );

      await expectLater(
        service.streamReply(
          apiKey: _apiKey,
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(isA<AiException>()),
      );
    });

    test('kegagalan koneksi menjadi pesan jaringan', () async {
      final service = AiService(
        client: MockClient((_) async {
          throw http.ClientException('offline');
        }),
      );

      await expectLater(
        service.streamReply(
          apiKey: _apiKey,
          history: const [AiTurn(role: AiRole.user, text: 'Halo')],
          onChunk: (_) {},
        ),
        throwsA(
          isA<AiException>().having(
            (error) => error.kind,
            'kind',
            AiErrorKind.network,
          ),
        ),
      );
    });
  });

  group('AiConfig.validateApiKey', () {
    test('menolak key kosong, terlalu pendek, dan mengandung spasi', () {
      expect(AiConfig.validateApiKey(''), isNotNull);
      expect(AiConfig.validateApiKey('pendek'), isNotNull);
      expect(
        AiConfig.validateApiKey('key dengan spasi panjang sekali'),
        isNotNull,
      );
    });

    test('menerima key yang wajar', () {
      expect(AiConfig.validateApiKey(_apiKey), isNull);
    });
  });
}
