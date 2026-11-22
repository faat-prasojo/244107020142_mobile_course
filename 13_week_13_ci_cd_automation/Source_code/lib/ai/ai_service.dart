import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_config.dart';
import 'ai_exception.dart';
import 'ai_models.dart';

/// Komunikasi HTTP ke Gemini API. Tidak tahu apa-apa soal UI/state.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Mengirim riwayat percakapan dan memanggil [onChunk] untuk setiap potongan
  /// teks yang diterima (server-sent events).
  Future<void> streamReply({
    required String apiKey,
    required List<AiTurn> history,
    required void Function(String chunk) onChunk,
    String? announcementContext,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) throw AiException.missingKey;

    final request = http.Request('POST', Uri.parse(AiConfig.endpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'x-goog-api-key': key,
      })
      ..body = jsonEncode(
        AiConfig.requestBody(
          history: history,
          announcementContext: announcementContext,
        ),
      );

    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(AiConfig.connectTimeout);
    } on TimeoutException {
      throw AiException.timeout;
    } on http.ClientException {
      throw AiException.network;
    } on Exception {
      throw AiException.network;
    }

    if (response.statusCode != 200) {
      // Body error tidak ditampilkan mentah-mentah ke pengguna.
      try {
        await response.stream.bytesToString().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {
        // Diabaikan: status code sudah cukup untuk menentukan pesan.
      }
      throw AiException.fromStatus(response.statusCode);
    }

    var receivedText = false;
    try {
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(AiConfig.idleTimeout);

      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;

        Map<String, dynamic> event;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is! Map<String, dynamic>) continue;
          event = decoded;
        } on FormatException {
          continue;
        }

        final error = event['error'];
        if (error is Map) {
          throw const AiException(
            'Layanan AI menolak permintaan. Coba lagi dengan pertanyaan lain.',
          );
        }

        if (event['event_type'] != 'step.delta') continue;
        final delta = event['delta'];
        if (delta is! Map || delta['type'] != 'text') continue;
        final text = delta['text'];
        if (text is! String || text.isEmpty) continue;

        receivedText = true;
        onChunk(text);
      }
    } on TimeoutException {
      throw AiException.timeout;
    } on http.ClientException {
      throw AiException.network;
    }

    if (!receivedText) throw AiException.emptyResponse;
  }

  void dispose() => _client.close();
}
