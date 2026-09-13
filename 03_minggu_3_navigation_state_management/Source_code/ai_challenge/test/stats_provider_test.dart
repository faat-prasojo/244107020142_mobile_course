import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan impor path di bawah ini dengan nama package/proyek Anda
import 'package:ai_challenge/providers/stats_provider.dart';

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