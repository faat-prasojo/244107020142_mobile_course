import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/ai_providers.dart';
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
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Installation ID disalin')));
  }

  String _displayName(String? email) {
    if (email == null || email.isEmpty) return 'Mahasiswa';
    final name = email.split('@').first;
    if (name.isEmpty) return 'Mahasiswa';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider);
    final push = ref.watch(pushServiceProvider);
    final keyStatus = ref.watch(aiKeyStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, const Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Campus Notify'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan AI',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.aiSettings),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'Halo, ${_displayName(user?.email)} 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apa yang ingin kamu ketahui tentang kampus hari ini?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 18),
          _AssistantHero(
            aiReady: keyStatus.value == true,
            onOpenChat: () => context.push(AppRoutes.assistant),
            onOpenSettings: () => context.push(AppRoutes.aiSettings),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pengumuman Kampus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.announcement),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder(
            valueListenable: push.lastMessage,
            builder: (context, message, _) {
              if (message == null) {
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push(AppRoutes.announcement),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.campaign_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Belum ada pengumuman baru',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pengumuman dari kampus akan muncul di sini.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final title =
                  message.notification?.title ??
                  message.data['title']?.toString() ??
                  'Pengumuman kampus';
              final body =
                  message.notification?.body ??
                  message.data['body']?.toString() ??
                  'Buka untuk melihat detail pengumuman.';

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push(AppRoutes.announcement),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TERBARU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.devices_rounded,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text(
                'Perangkat & notifikasi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Topik: ${PushService.campusTopic}',
                style: const TextStyle(fontSize: 11.5),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.person_outline_rounded, size: 20),
                  title: const Text('Akun', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${user?.email ?? '-'} · UID ${maskToken(user?.uid)}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: push.fcmToken,
                  builder: (context, token, _) {
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                            size: 20,
                          ),
                          title: const Text(
                            'FCM Installation ID',
                            style: TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            token == null
                                ? 'Menunggu izin atau token dari perangkat'
                                : maskToken(token),
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        ),
                        if (token != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () => _copyToken(token),
                              icon: const Icon(Icons.copy_rounded, size: 17),
                              label: const Text('Salin ID'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Campus Notify · AI Campus Assistant',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha(160),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantHero extends StatelessWidget {
  const _AssistantHero({
    required this.aiReady,
    required this.onOpenChat,
    required this.onOpenSettings,
  });

  final bool aiReady;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withAlpha(45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
            Positioned(
              bottom: -45,
              right: 40,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(28),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'AI CAMPUS ASSISTANT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onOpenSettings,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                aiReady
                                    ? Icons.check_circle_rounded
                                    : Icons.key_rounded,
                                size: 12,
                                color: aiReady
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFDE68A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                aiReady ? 'AI siap' : 'Atur key',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanya Campus\nAssistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informasi akademik, pengumuman, dan kehidupan kampus '
                    'dalam satu percakapan.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: const Text('Mulai Chat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
