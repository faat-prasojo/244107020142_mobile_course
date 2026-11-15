import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../../domain/usecases/search_notes.dart';
import 'notes_providers.dart';

final searchNotesProvider = Provider<SearchNotes>((ref) => const SearchNotes());

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final searchNotes = ref.watch(searchNotesProvider);
  return ref
      .watch(notesProvider)
      .whenData((notes) => searchNotes(notes, query));
});
