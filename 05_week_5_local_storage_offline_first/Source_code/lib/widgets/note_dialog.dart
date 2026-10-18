import 'package:flutter/material.dart';
import '../data/local/note.dart';

// StatefulWidget supaya controller di-dispose setelah animasi tutup selesai.
// Dispose langsung setelah showDialog() berisiko crash "used after disposed".
// Dipindah dari notes_page.dart agar NotesPage dan NoteDetailPage bisa
// memakainya tanpa saling import (menghindari circular import).
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
