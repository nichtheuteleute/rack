import 'package:flutter/foundation.dart';

import '../../data/note.dart';
import '../../data/notes_storage.dart';

/// Which notes the list shows.
enum NotesFilter { all, open, done }

/// The notes, the active filter and the sort order.
///
/// Every change to the notes is persisted with [NotesStorage.save].
/// The sort order comes from the settings feature and is pushed in via
/// [newestFirst] by a `ChangeNotifierProxyProvider` (see `main.dart`).
class NotesModel extends ChangeNotifier {
  NotesModel(this._storage);

  final NotesStorage _storage;

  List<Note> _notes = const [];
  bool _isLoaded = false;
  NotesFilter _filter = NotesFilter.all;
  bool _newestFirst = false;

  /// Whether [load] has completed.
  bool get isLoaded => _isLoaded;

  NotesFilter get filter => _filter;

  bool get newestFirst => _newestFirst;

  /// Set from the settings feature; re-sorts [visibleNotes].
  set newestFirst(bool value) {
    if (value == _newestFirst) return;
    _newestFirst = value;
    notifyListeners();
  }

  /// Notes matching [filter], sorted by creation time ([newestFirst] aware).
  List<Note> get visibleNotes {
    final visible = _notes.where(
      (note) => switch (_filter) {
        NotesFilter.all => true,
        NotesFilter.open => !note.done,
        NotesFilter.done => note.done,
      },
    );
    final sorted = visible.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _newestFirst ? sorted.reversed.toList() : sorted;
  }

  /// Number of notes that are not done (independent of [filter]).
  int get openCount => _notes.where((note) => !note.done).length;

  Future<void> load() async {
    _notes = List.unmodifiable(await _storage.load());
    _isLoaded = true;
    notifyListeners();
  }

  void setFilter(NotesFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  /// Whether [text] is a valid new note.
  bool canAdd(String text) => text.trim().isNotEmpty;

  /// Adds a note with the trimmed [text]. Ignores blank text.
  Future<void> add(String text) async {
    if (!canAdd(text)) return;
    final note = Note(
      id: _storage.newId(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _update([..._notes, note]);
  }

  /// Flips the done state of the note with [id].
  Future<void> toggle(String id) => _update([
    for (final note in _notes)
      note.id == id ? note.copyWith(done: !note.done) : note,
  ]);

  Future<void> _update(List<Note> notes) async {
    _notes = List.unmodifiable(notes);
    notifyListeners();
    await _storage.save(_notes);
  }
}
