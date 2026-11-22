import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/ai_chat_controller.dart';
import '../ai/ai_config.dart';
import '../ai/ai_models.dart';
import '../ai/ai_providers.dart';
import '../messaging/push_service.dart';
import '../router/app_router.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _input = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _input
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final hasText = _input.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;

    if (ref.read(aiKeyStatusProvider).value == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key belum diatur. Atur di Pengaturan AI dulu.'),
        ),
      );
      return;
    }

    ref
        .read(aiChatControllerProvider.notifier)
        .send(text, announcementContext: _announcementContext());

    if (preset == null) _input.clear();
  }

  String? _announcementContext() {
    final message = ref.read(pushServiceProvider).lastMessage.value;
    if (message == null) return null;

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return null;

    return 'Judul: ${title ?? '-'}\nIsi: ${body ?? '-'}';
  }

  void _openSettings() => context.push(AppRoutes.aiSettings);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    final keyStatus = ref.watch(aiKeyStatusProvider);
    final missingKey = keyStatus.value == false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary
                  .withAlpha(28),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 19,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'AI Campus Assistant',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan AI',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Chat baru',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isSending
                ? null
                : () => ref.read(aiChatControllerProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (missingKey) _MissingKeyBanner(onPressed: _openSettings),
          if (state.errorMessage != null && !missingKey)
            _InlineError(
              message: state.errorMessage!,
              onPressed: _openSettings,
            ),
          Expanded(
            child: state.isEmpty
                ? _WelcomeView(
                    missingKey: missingKey,
                    isSending: state.isSending,
                    onSuggestion: (text) {
                      if (missingKey) {
                        _openSettings();
                      } else {
                        _send(text);
                      }
                    },
                  )
                : _MessageList(
                    messages: state.messages,
                    onRetry: () =>
                        ref.read(aiChatControllerProvider.notifier).retry(),
                  ),
          ),
          _Composer(
            controller: _input,
            canSend: _hasText && !state.isSending,
            isSending: state.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MissingKeyBanner extends StatelessWidget {
  const _MissingKeyBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(Icons.key_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'API key belum diatur. Tambahkan API key Gemini untuk mulai bertanya.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          TextButton(onPressed: onPressed, child: const Text('Atur')),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onPressed});

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12.5)),
          ),
          TextButton(onPressed: onPressed, child: const Text('Pengaturan')),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    required this.missingKey,
    required this.isSending,
    required this.onSuggestion,
  });

  final bool missingKey;
  final bool isSending;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, const Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Halo, saya Campus Assistant',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tanyakan informasi perkuliahan, akademik, pengumuman, atau kegiatan '
          'kampus. Saya akan menjawab sesuai informasi yang tersedia.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Coba tanyakan',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...AiConfig.suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isSending ? null : () => onSuggestion(suggestion),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 19,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withAlpha(70),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 19,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI dapat keliru. Selalu verifikasi jadwal, kebijakan, dan '
                  'pengumuman resmi melalui kanal kampus.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (missingKey)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton.icon(
              onPressed: () => onSuggestion(AiConfig.suggestions.first),
              icon: const Icon(Icons.key_rounded),
              label: const Text('Atur API Key'),
            ),
          ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.onRetry});

  final List<ChatMessage> messages;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _MessageBubble(message: message, onRetry: onRetry);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: SelectableText(
            message.text,
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
        ),
      );
    }

    final isError = message.isError;
    final background = isError
        ? colorScheme.errorContainer.withAlpha(150)
        : (theme.cardTheme.color ?? colorScheme.surface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: isError
                ? colorScheme.error.withAlpha(30)
                : colorScheme.primary.withAlpha(24),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.auto_awesome_rounded,
              size: 17,
              color: isError ? colorScheme.error : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isError
                      ? colorScheme.error.withAlpha(60)
                      : colorScheme.outlineVariant.withAlpha(110),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isStreaming && message.text.isEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Sedang menyiapkan jawaban...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    )
                  else
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        height: 1.45,
                        color: isError ? colorScheme.onErrorContainer : null,
                      ),
                    ),
                  if (message.isStreaming && message.text.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  if (isError) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: AiConfig.maxInputLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => null,
                decoration: const InputDecoration(
                  hintText: 'Tanyakan sesuatu tentang kampus...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton.filled(
                key: const Key('send-button'),
                tooltip: 'Kirim',
                onPressed: canSend ? onSend : null,
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
