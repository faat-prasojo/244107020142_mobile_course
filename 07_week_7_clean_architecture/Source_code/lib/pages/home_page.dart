import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/token_store.dart';
import '../messaging/push_service.dart';
import '../router/app_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Tunggu frame pertama supaya router benar-benar siap sebelum FCM
    // mencoba navigasi dari getInitialMessage (kasus terminated).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pushServiceProvider).start(ref.read(appRouterProvider));
    });
  }

  Future<void> _logout() async {
    await ref.read(pushServiceProvider).stop();
    await ref.read(authControllerProvider.notifier).signOut();
    // Redirect ke /login ditangani router.
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token FCM disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final push = ref.watch(pushServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user?.email ?? '-'),
              subtitle: Text('UID: ${maskToken(user?.uid)}'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<String?>(
                valueListenable: push.fcmToken,
                builder: (context, token, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FCM device token',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(token == null
                          ? 'Belum tersedia (menunggu izin / token)'
                          : maskToken(token)),
                      const SizedBox(height: 4),
                      Text('Topic: ${PushService.campusTopic}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: token == null ? null : () => _copyToken(token),
                        icon: const Icon(Icons.copy),
                        label: const Text('Salin token untuk uji Console'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.announcement),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Lihat pengumuman'),
          ),
        ],
      ),
    );
  }
}
