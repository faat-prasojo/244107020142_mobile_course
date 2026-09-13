import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_challenge/main.dart';

void main() {
  testWidgets('StatsPage smoke test', (WidgetTester tester) async {
    // Membangun aplikasi dengan ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Menggunakan pumpAndSettle untuk menunggu animasi atau delay selesai
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Memverifikasi bahwa judul halaman Statistik Aplikasi muncul
    expect(find.text('Statistik Aplikasi'), findsOneWidget);
  });
}