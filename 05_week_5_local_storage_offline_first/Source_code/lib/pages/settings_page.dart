import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';
import '../data/providers.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

// Nilai "terakhir dibuka" dibaca di main() sebelum ditimpa, lalu di-override.
final lastOpenedProvider = Provider<String?>((ref) => null);

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  // Beda dari codelab: tidak memakai state = AsyncLoading(), karena itu
  // membuat tema berkedip ke terang sesaat saat toggle.
  Future<void> toggle() async {
    final next = !(state.value ?? false);
    await ref.read(prefsRepositoryProvider).setDarkMode(next);
    state = AsyncData(next);
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(darkModeProvider).value ?? false;
    final offline = ref.watch(forceOfflineProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode gelap'),
            value: dark,
            onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          SwitchListTile(
            title: const Text('Paksa offline (simulasi)'),
            subtitle: const Text('Memblokir fetch posts dan sync catatan'),
            value: offline,
            onChanged: (_) => ref.read(forceOfflineProvider.notifier).toggle(),
          ),
          ListTile(
            title: const Text('Terakhir dibuka'),
            subtitle: Text(lastOpened ?? 'Pertama kali dibuka'),
          ),
        ],
      ),
    );
  }
}