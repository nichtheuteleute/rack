import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/note.dart';
import '../notes/notes_providers.dart';

part 'search_providers.g.dart';

/// The text typed on the search screen. Reset when the screen closes.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void change(String query) => state = query;
}

/// Notes whose text contains the trimmed query, case-insensitive, in the
/// current sort order. Empty for an empty query.
@riverpod
List<Note> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return const [];
  return [
    for (final note in ref.watch(sortedNotesProvider))
      if (note.text.toLowerCase().contains(query)) note,
  ];
}
