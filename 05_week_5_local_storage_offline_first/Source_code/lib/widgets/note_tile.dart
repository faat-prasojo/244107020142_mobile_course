import 'package:flutter/material.dart';
import '../data/local/note.dart';

/// Baris catatan di halaman list. Dipisah dari NotesPage supaya bisa
/// di-widget-test sendiri tanpa Riverpod atau SQLite.
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.body.isNotEmpty)
            Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          // Badge hanya muncul untuk catatan yang belum masuk antrean sync selesai.
          if (note.dirty) const UnsyncedBadge(),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Hapus',
        onPressed: onDelete,
      ),
    );
  }
}

/// Lencana "belum tersinkron". Public karena dipakai juga di halaman detail.
class UnsyncedBadge extends StatelessWidget {
  const UnsyncedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'belum tersinkron',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}
