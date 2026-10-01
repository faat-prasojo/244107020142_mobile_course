import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/prefs.dart';
import 'pages/notes_page.dart';
import 'pages/posts_page.dart';
import 'pages/settings_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // wajib sebelum akses plugin di main()

  // Baca waktu buka sebelumnya, baru timpa dengan waktu sekarang.
  final prefs = PrefsRepository();
  final previous = await prefs.getLastOpened();
  await prefs.markOpenedNow();

  runApp(ProviderScope(
    overrides: [lastOpenedProvider.overrideWithValue(previous)],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider).value ?? false;
    return MaterialApp(
      title: 'Week 5 - Offline Notes',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // IndexedStack menjaga ketiga halaman tetap hidup, jadi ref di halaman
  // catatan tidak invalid saat sync masih berjalan lalu user pindah tab.
  // Trade-off: ketiga halaman dibangun saat startup.
  static const _pages = [NotesPage(), PostsPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note_alt_outlined), label: 'Catatan'),
          NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Posts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Pengaturan'),
        ],
      ),
    );
  }
}