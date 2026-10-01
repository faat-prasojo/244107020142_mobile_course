import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/providers.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';

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
                    onTap: () => _showNoteDialog(context, ref, note: note),
                    onDelete: () => _delete(ref, note),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }

  Future<void> _delete(WidgetRef ref, Note note) async {
    await ref.read(noteRepositoryProvider).deleteNote(note.id!);
    _refresh(ref);
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    WidgetRef ref, {
    Note? note,
  }) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => NoteDialog(note: note),
    );
    if (result == null || result.$1.isEmpty) return;

    final repo = ref.read(noteRepositoryProvider);
    if (note == null) {
      await repo.addNote(title: result.$1, body: result.$2);
    } else {
      await repo.updateNote(id: note.id!, title: result.$1, body: result.$2);
    }
    _refresh(ref);
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
    _refresh(ref);
    messenger.showSnackBar(
      SnackBar(content: Text('$count catatan tersinkron.')),
    );
  }
}

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
          if (note.dirty)
            Text(
              'belum tersinkron',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}

// StatefulWidget supaya controller di-dispose setelah animasi tutup selesai.
// Dispose langsung setelah showDialog() berisiko crash "used after disposed".
class NoteDialog extends StatefulWidget {
  const NoteDialog({super.key, this.note});
  final Note? note;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Catatan baru' : 'Edit catatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Judul'),
          ),
          TextField(
            controller: _body,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Isi'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (_title.text.trim(), _body.text.trim())),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}