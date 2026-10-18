import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/local/note.dart';
import '../data/providers.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Label selalu tampil (termasuk "0") supaya bisa jadi bukti screenshot.
          Badge(
            label: Text('$dirtyCount'),
            child: IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sinkronkan',
              onPressed: () => _sync(context, ref),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat catatan: $err')),
        data: (notes) => notes.isEmpty
            ? const Center(
                child: Text('Belum ada catatan. Tekan + untuk menambah.'))
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, i) {
                  final note = notes[i];
                  return NoteTile(
                    note: note,
                    // Hanya kirim id lewat URL. Halaman detail membaca
                    // sendiri dari repository, bukan dari list ini.
                    onTap: () => context.push('/note/${note.id}'),
                    onDelete: () => _delete(ref, note),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(WidgetRef ref, Note note) async {
    await ref.read(noteRepositoryProvider).deleteNote(note.id!);
    ref.refreshNotes();
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const NoteDialog(),
    );
    if (result == null || result.$1.isEmpty) return;

    await ref
        .read(noteRepositoryProvider)
        .addNote(title: result.$1, body: result.$2);
    ref.refreshNotes();
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context); // ambil sebelum await
    if (ref.read(forceOfflineProvider)) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Mode offline aktif: sinkronisasi ditunda.'),
      ));
      return;
    }
    final count = await syncNotes(ref.read(noteRepositoryProvider));
    ref.refreshNotes();
    messenger.showSnackBar(
      SnackBar(content: Text('$count catatan tersinkron.')),
    );
  }
}
