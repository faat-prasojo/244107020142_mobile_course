import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier untuk mengelola state statistik secara asinkron
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchStats();
  }

  // Metode privat untuk mensimulasikan pengambilan data dari server/API
  Future<List<String>> _fetchStats() async {
    // Simulasi jeda jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Mensimulasikan kegagalan acak sebesar 30%
    final random = Random();
    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal terhubung ke server statistik');
    }

    // Mengembalikan data statistik tiruan jika berhasil
    return [
      'Total Pengguna: 1,250',
      'Pendapatan Bulanan: Rp 15.4jt',
      'Aktivitas Aktif: 340 Sesi',
    ];
  }

  // Metode untuk memuat ulang data (digunakan saat tombol retry ditekan)
  Future<void> refreshStats() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

// Inisialisasi AsyncNotifierProvider agar dapat diakses oleh UI dan dites
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);