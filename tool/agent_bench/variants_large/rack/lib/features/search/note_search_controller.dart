import 'package:flutter/widgets.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../data/note.dart';
import '../notes/notes_store.dart';

/// Controller of the search screen: finds notes by text. (Named to avoid
/// clashing with Material's `SearchController`.)
class NoteSearchController implements Disposable {
  NoteSearchController({required NotesStore notesStore}) : _notes = notesStore;

  final NotesStore _notes;

  /// Text of the search field.
  final query = TextEditingController();
  late final _queryValue = query.toSignal();

  /// Notes whose text contains the trimmed query (case-insensitive), in the
  /// configured sort order. Empty while the query is empty.
  late final ReadonlySignal<List<Note>> results = computed(() {
    final q = _queryValue.value.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final note in _notes.notes.value)
        if (note.text.toLowerCase().contains(q)) note,
    ];
  });

  @override
  void dispose() {
    results.dispose();
    _queryValue.dispose();
    query.dispose();
  }
}
