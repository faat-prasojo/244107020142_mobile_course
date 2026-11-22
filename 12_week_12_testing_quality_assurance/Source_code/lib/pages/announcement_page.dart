import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../router/app_router.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final push = ref.watch(pushServiceProvider);

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
        title: const Text('Pengumuman'),
      ),
      body: ValueListenableBuilder(
        valueListenable: push.lastMessage,
        builder: (context, message, _) {
          if (message == null) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Belum ada pengumuman',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pengumuman yang dikirim kampus melalui Firebase Cloud '
                  'Messaging akan muncul di halaman ini.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.assistant),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Tanya Campus Assistant'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
                  child: const Text('Kembali ke Dashboard'),
                ),
              ],
            );
          }

          final title =
              message.notification?.title ??
              message.data['title']?.toString() ??
              '(tanpa judul)';
          final body =
              message.notification?.body ??
              message.data['body']?.toString() ??
              '(tanpa isi)';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PENGUMUMAN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.campaign_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                        ),
                      ),
                      if (message.sentTime != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Diterima: ${message.sentTime}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.assistant),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Tanya AI tentang pengumuman ini'),
              ),
              const SizedBox(height: 8),
              Text(
                'Campus Assistant akan memakai isi pengumuman terbaru sebagai '
                'konteks, tanpa mengarang informasi tambahan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 18),
              Card(
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: const Icon(Icons.code_rounded, size: 20),
                  title: const Text(
                    'Detail teknis',
                    style: TextStyle(fontSize: 13.5),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        'Data payload: ${message.data}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (message.messageId != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Message ID: ${message.messageId}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
