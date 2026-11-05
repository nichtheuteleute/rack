import 'package:flutter/widgets.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../data/note.dart';
import '../archive/archive_store.dart';
import 'notes_filter.dart';
import 'notes_store.dart';

/// Controller of the notes screen: the input field, the selected filter and
/// the notes it shows.
class NotesController implements Disposable {
  NotesController({
    required NotesStore notesStore,
    required ArchiveStore archiveStore,
  })  : _notes = notesStore,
        _archive = archiveStore;

  final NotesStore _notes;
  final ArchiveStore _archive;

  /// Text of the input field for a new note.
  final input = TextEditingController();
  late final _inputValue = input.toSignal();

  final _filter = signal(NotesFilter.all);
  ReadonlySignal<NotesFilter> get filter => _filter;

  /// Whether the input holds text that can be added as a note.
  late final ReadonlySignal<bool> canAdd =
      computed(() => _inputValue.value.text.trim().isNotEmpty);

  /// The notes matching [filter], in the configured sort order.
  late final ReadonlySignal<List<Note>> visibleNotes = computed(
    () => _notes.notes.value.where(_filter.value.matches).toList(),
  );

  ReadonlySignal<int> get openCount => _notes.openCount;

  void selectFilter(NotesFilter filter) => _filter.value = filter;

  /// Adds the trimmed input as a new note and clears the input.
  Future<void> add() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    await _notes.add(text);
  }

  Future<void> toggle(Note note) => _notes.toggle(note.id);

  Future<void> archive(Note note) => _archive.archive(note);

  @override
  void dispose() {
    visibleNotes.dispose();
    canAdd.dispose();
    _filter.dispose();
    _inputValue.dispose();
    input.dispose();
  }
}
