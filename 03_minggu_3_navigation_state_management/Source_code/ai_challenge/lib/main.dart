import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/stats_page.dart'; // Impor file StatsPage yang sudah dibuat

void main() {
  // ProviderScope wajib ada di paling atas agar Riverpod dapat berfungsi
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stats App Riverpod',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      // Menjadikan StatsPage sebagai halaman utama aplikasi
      home: const StatsPage(),
    );
  }
}