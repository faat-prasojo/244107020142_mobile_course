import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_providers.dart';

class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.index});
  
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca daftar todo dari provider utama
    final todos = ref.watch(todoListProvider);
    final todo = todos[index];

    return ListTile(
      leading: Checkbox(
        value: todo.done,
        onChanged: (_) => ref.read(todoListProvider.notifier).toggle(index),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => ref.read(todoListProvider.notifier).remove(index),
      ),
    );
  }
}