import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../router/app_router.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // go() menggantikan stack, jadi tombol back eksplisit ke /home.
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ValueListenableBuilder<RemoteMessage?>(
        valueListenable: push.lastMessage,
        builder: (context, message, _) {
          if (message == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada pengumuman.\nKirim pesan dari Firebase Console untuk mencoba.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final title = message.notification?.title ??
              message.data['title']?.toString() ??
              '(tanpa judul)';
          final body = message.notification?.body ??
              message.data['body']?.toString() ??
              '(tanpa isi)';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(body),
                      const Divider(height: 32),
                      Text('Data payload: ${message.data}',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (message.sentTime != null)
                        Text('Dikirim: ${message.sentTime}',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
