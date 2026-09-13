import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state dari statsProvider
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
        actions: [
          // Tombol untuk melakukan refresh manual pada data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(statsProvider.notifier).refreshStats(),
          ),
        ],
      ),
      // Menggunakan method .when() untuk menangani 3 kondisi state asinkron
      body: statsAsync.when(
        // 1. Kondisi saat data sedang dimuat
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        // 2. Kondisi saat terjadi error/kegagalan
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terjadi kesalahan: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 12),
                // Tombol retry untuk mencoba mengambil data kembali
                FilledButton.icon(
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh), // Diubah dari Icons.retry yang tidak valid
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        // 3. Kondisi saat data berhasil dimuat (Success)
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: Text(stats[index]),
            ),
          ),
        ),
      ),
    );
  }
}