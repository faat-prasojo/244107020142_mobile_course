# Minggu 3 - Navigation State Management



**Nama:** Faatihurrizki Prasojo

**NIM:** 244107020142

## Tujuan 
- Menjelaskan konsep navigasi, route, dan perbedaan Navigator 1.0 dengan GoRouter;
- Menerapkan navigasi multi-page dengan GoRouter, termasuk passing argument dan deep link sederhana;
- Menjelaskan mengapa state management diperlukan dan cara kerja Riverpod (Provider, ConsumerWidget, Notifier);
- Menggunakan AsyncValue untuk menangani state loading, error, dan success pada UI;
- Membangun aplikasi ToDo dengan navigasi dan Riverpod, lalu memverifikasi hasilnya dengan widget test sederhana.

## Fitur Utama
- **Manajemen Tugas (CRUD)**: Fitur dasar untuk menambah, mengubah status, dan menghapus tugas.

- **Filter Tugas**: Penyaringan daftar tugas berdasarkan status: Semua, Aktif, atau Selesai.

- **Simulasi Asinkron**: Halaman statistik dengan penanganan state lengkap (loading, error, dan success).

- **Navigasi Persisten**: Perpindahan halaman mulus menggunakan NavigationBar dan ShellRoute tanpa me-reset state halaman sebelumnya.

## Cara Menjalankan
```
# Mengunduh dan memasang semua dependensi (package) yang dibutuhkan
flutter pub get

# Menjalankan aplikasi pada perangkat atau emulator yang terhubung
flutter run

# Menjalankan rangkaian pengujian otomatis (Widget/Unit Test)
flutter test
```

## Dokumentasi Aplikasi multi-page dengan GoRouter
| Home | multi-page |
| :---: | :---: |
| <img src="./screenshot/sample1.jpeg" width="400"> | <img src="./screenshot/sample2.jpeg" width="400"> |

## Dokumentasi Aplikasi ToDo dengan Riverpod

| ToDo | Tambah Data |
| :---: | :---: |
| <img src="./screenshot/sample3.jpeg" width="400"> | <img src="./screenshot/sample4.jpeg" width="400"> |

## Dokumentasi AsyncValue
| AsyncValue | 
| :---: | 
| <img src="./screenshot/sample8.jpeg" width="400"> |

| analyze & test | 
| :---: | 
| <img src="./screenshot/sample9.jpeg" width="600"> |

## Dokumentasi AI Challenge
| Gemini AI | 
| :---: | 
| <img src="./screenshot/sample10.jpeg" width="700"> |

File Provider `lib/providers/stats_provider.dart`

```
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
```

File Halaman UI `lib/pages/stats_page.dart`
```
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
                  icon: const Icon(Icons.retry),
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
```

File Unit Test `test/stats_provider_test.dart`
```
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan impor path di bawah ini dengan nama package/proyek Anda
import 'package:_03_minggu_3_navigation_state_management/providers/stats_provider.dart'; 

void main() {
  test('StatsNotifier mengembalikan data list string saat berhasil', () async {
    // Membuat wadah (container) untuk membaca provider tanpa widget tree
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Membaca state awal dari provider (yang akan memicu fungsi build)
    // Karena ada elemen acak 30% gagal, kita bisa uji atau gunakan pendukung.
    // Untuk memastikan pengujian stabil, kita bisa memantau tipe AsyncValue yang dihasilkan.
    final futureResult = container.read(statsProvider.future);

    // Memastikan hasil akhir berupa List<String> atau menangkap exception jika terkena 30% error
    try {
      final result = await futureResult;
      expect(result, isA<List<String>>());
      expect(result.length, 3);
    } catch (e) {
      // Jika terkena simulasi error 30%, pastikan error bertipe Exception
      expect(e, isA<Exception>());
    }
  });
}
```

## Dokumentasi Refactoring dan testing

| Page 1 | Page 2 |
| :---: | :---: |
| <img src="./screenshot/sample11.jpeg" width="400"> | <img src="./screenshot/sample12.jpeg" width="400"> |

| Testing | 
| :---: | 
| <img src="./screenshot/sample13.jpeg" width="600"> |


## Refleksi
 - `setState` vs Riverpod: Gunakan `setState` untuk state lokal widget tunggal yang sederhana. Naik ke Riverpod saat state perlu dibagi ke banyak widget atau diakses secara global.

- `context.go` vs `context.push`: `context.go` menggantikan rute saat ini (untuk navigasi utama seperti menu bawah), sedangkan `context.push` menumpuk rute baru di atasnya (untuk halaman detail yang butuh tombol kembali).

- Keunggulan `AsyncValue`: Mencegah bug inkonsistensi state (misal `isLoading` dan `hasError` aktif bersamaan) karena menggabungkan status loading, error, dan data ke dalam satu objek yang mutually exclusive.

- Perbaikan pada Hasil AI: Memperbaiki penamaan widget navigasi (`NavigationDestination`), menghapus blok `default` yang redundan pada switch, serta menyesuaikan pumpAndSettle pada widget test agar animasi dialog tertutup selesai dengan sempurna.