import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_config.dart';
import 'ai_exception.dart';
import 'ai_models.dart';
import 'ai_providers.dart';

final aiChatControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);

/// State management chat: validasi input, pemanggilan service, streaming,
/// dan status loading/error.
class AiChatController extends Notifier<AiChatState> {
  String? _lastPrompt;
  String? _lastContext;
  bool _busy = false;

  @override
  AiChatState build() => const AiChatState();

  Future<void> send(String raw, {String? announcementContext}) async {
    if (_busy) return;

    final text = raw.trim();
    if (text.isEmpty) return;
    if (text.length > AiConfig.maxInputLength) {
      state = state.copyWith(
        errorMessage:
            'Pesan terlalu panjang (maksimal ${AiConfig.maxInputLength} karakter).',
      );
      return;
    }

    _busy = true;
    try {
      final key = await _readKey();
      if (key == null) {
        state = state.copyWith(errorMessage: AiException.missingKey.message);
        return;
      }

      _lastPrompt = text;
      _lastContext = announcementContext;

      final history = [
        ..._historyFrom(state.messages),
        AiTurn(role: AiRole.user, text: text),
      ];

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage.user(text),
          const ChatMessage.assistantStreaming(),
        ],
        isSending: true,
        clearError: true,
      );

      await _request(key: key, history: history);
    } finally {
      _busy = false;
    }
  }

  /// Mengulang request terakhir tanpa menduplikasi bubble pengguna.
  Future<void> retry() async {
    if (_busy || state.isSending) return;
    if (_lastPrompt == null) return;

    _busy = true;
    try {
      final key = await _readKey();
      if (key == null) {
        state = state.copyWith(errorMessage: AiException.missingKey.message);
        return;
      }

      final messages = [...state.messages];
      while (messages.isNotEmpty && messages.last.isError) {
        messages.removeLast();
      }
      if (messages.isEmpty || !messages.last.isUser) return;

      state = state.copyWith(
        messages: [...messages, const ChatMessage.assistantStreaming()],
        isSending: true,
        clearError: true,
      );

      await _request(key: key, history: _historyFrom(messages));
    } finally {
      _busy = false;
    }
  }

  void clear() {
    if (state.isSending) return;
    _lastPrompt = null;
    _lastContext = null;
    state = const AiChatState();
  }

  Future<String?> _readKey() async {
    final key = await ref.read(aiKeyStoreProvider).readKey();
    if (key == null || key.trim().isEmpty) return null;
    return key.trim();
  }

  Future<void> _request({
    required String key,
    required List<AiTurn> history,
  }) async {
    final buffer = StringBuffer();
    try {
      await ref
          .read(aiServiceProvider)
          .streamReply(
            apiKey: key,
            history: history,
            announcementContext: _lastContext,
            onChunk: (chunk) {
              if (!ref.mounted) return;
              buffer.write(chunk);
              _updateLastAssistant(
                buffer.toString(),
                ChatMessageStatus.streaming,
              );
            },
          );

      if (!ref.mounted) return;
      if (buffer.isEmpty) throw AiException.emptyResponse;

      _updateLastAssistant(buffer.toString(), ChatMessageStatus.done);
      state = state.copyWith(isSending: false);
    } on AiException catch (error) {
      if (!ref.mounted) return;
      _updateLastAssistant(error.message, ChatMessageStatus.error);
      state = state.copyWith(isSending: false);
    } catch (_) {
      if (!ref.mounted) return;
      _updateLastAssistant(
        'Terjadi kesalahan saat menghubungi layanan AI. Coba lagi.',
        ChatMessageStatus.error,
      );
      state = state.copyWith(isSending: false);
    }
  }

  List<AiTurn> _historyFrom(List<ChatMessage> messages) {
    return messages
        .where(
          (message) =>
              message.status == ChatMessageStatus.done &&
              message.text.trim().isNotEmpty,
        )
        .map((message) => AiTurn(role: message.role, text: message.text.trim()))
        .toList();
  }

  void _updateLastAssistant(String text, ChatMessageStatus status) {
    final messages = [...state.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role != AiRole.model) return;
    messages[messages.length - 1] = last.copyWith(text: text, status: status);
    state = state.copyWith(messages: messages);
  }
}
