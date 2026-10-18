import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_tile.dart';

/// Detail catatan untuk route `/note/:id`.
/// Data dibaca dari repository lewat [noteByIdProvider], jadi tetap benar
/// kalau halaman dibuka langsung dari URL tanpa melewati halaman list.
class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(id));
    final note = noteAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail catatan'),
        actions: [
          if (note != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _edit(context, ref, note),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat catatan: $err')),
        data: (loaded) {
          // null = id tidak ada di database (sudah dihapus atau URL salah).
          if (loaded == null) {
            return const Center(child: Text('Catatan tidak ditemukan.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(loaded.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Diubah ${_formatDate(loaded.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (loaded.dirty) const UnsyncedBadge(),
              const SizedBox(height: 16),
              Text(loaded.body.isEmpty ? '(tanpa isi)' : loaded.body),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Note note) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => NoteDialog(note: note),
    );
    if (result == null || result.$1.isEmpty) return;

    await ref
        .read(noteRepositoryProvider)
        .updateNote(id: id, title: result.$1, body: result.$2);
    ref.refreshNotes();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    ref.refreshNotes();
    if (context.mounted) context.pop(); // balik ke list setelah dihapus
  }
}

/// Dipakai router saat bagian `:id` bukan angka, misalnya `/note/abc`.
class InvalidNotePage extends StatelessWidget {
  const InvalidNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail catatan')),
      body: const Center(child: Text('Alamat catatan tidak valid.')),
    );
  }
}

String _formatDate(DateTime d) {
  final t = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}
