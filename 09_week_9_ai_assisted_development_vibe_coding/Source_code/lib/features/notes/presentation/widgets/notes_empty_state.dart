import 'package:flutter/material.dart';

class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({
    super.key,
    required this.isSearching,
    required this.onCreate,
    required this.onClearSearch,
  });

  final bool isSearching;
  final VoidCallback onCreate;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withAlpha(isDark ? 40 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.note_alt_outlined,
                size: 48,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Tidak ada catatan yang cocok dengan pencarian.'
                  : 'Belum ada catatan bisnis.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Coba kata kunci pencarian yang lain.'
                  : 'Tekan tombol "Tambah Catatan" untuk membuat entity baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isSearching ? onClearSearch : onCreate,
              icon: Icon(isSearching ? Icons.clear : Icons.add_rounded),
              label: Text(
                isSearching ? 'Hapus Pencarian' : 'Buat Catatan Pertama',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
