import 'package:flutter/material.dart';
import 'notes_page.dart';
import 'posts_page.dart';
import 'settings_page.dart';

// Dipindah dari main.dart agar router.dart bisa mengimpornya tanpa
// circular import (main.dart -> router.dart -> main.dart).
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
