import 'dart:async';

import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';

/// Something that happened to a note, for features that react to it
/// (e.g. the activity log).
sealed class NoteChange {
  const NoteChange(this.note);

  final Note note;
}

final class NoteAdded extends NoteChange {
  const NoteAdded(super.note);
}

/// A note went from open to done.
final class NoteCompleted extends NoteChange {
  const NoteCompleted(super.note);
}

/// Domain layer for notes and the archive.
///
/// Wraps [NotesStorage] and [ArchiveStorage], persists every change and
/// publishes the lists as streams, so several blocs stay in sync without
/// knowing each other. Call [load] once before use.
class NotesRepository {
  NotesRepository({required this._notesStorage, required this._archiveStorage});

  final NotesStorage _notesStorage;
  final ArchiveStorage _archiveStorage;
  final _notes = _LatestValue<List<Note>>();
  final _archive = _LatestValue<List<Note>>();
  final _changes = StreamController<NoteChange>.broadcast();

  /// The notes list (storage order); replays the current list on listen.
  Stream<List<Note>> get notes => _notes.stream;

  /// Archived notes (archive order); replays the current list on listen.
  Stream<List<Note>> get archive => _archive.stream;

  Stream<NoteChange> get changes => _changes.stream;

  Future<void> load() async {
    final (notes, archive) = await (
      _notesStorage.load(),
      _archiveStorage.load(),
    ).wait;
    _notes.value = notes;
    _archive.value = archive;
  }

  Future<void> addNote(String text) async {
    final note = Note(
      id: _notesStorage.newId(),
      text: text,
      createdAt: DateTime.now(),
    );
    _notes.value = [..._notes.value, note];
    _changes.add(NoteAdded(note));
    await _notesStorage.save(_notes.value);
  }

  Future<void> toggleNote(String id) async {
    final note = _find(_notes.value, id);
    final toggled = note.copyWith(done: !note.done);
    _notes.value = [
      for (final other in _notes.value) other.id == id ? toggled : other,
    ];
    if (toggled.done) _changes.add(NoteCompleted(toggled));
    await _notesStorage.save(_notes.value);
  }

  Future<void> archiveNote(String id) async {
    final note = _find(_notes.value, id);
    _notes.value = _without(_notes.value, id);
    _archive.value = [..._archive.value, note];
    await (
      _notesStorage.save(_notes.value),
      _archiveStorage.save(_archive.value),
    ).wait;
  }

  /// Moves an archived note back into the notes list, unchanged.
  Future<void> restoreNote(String id) async {
    final note = _find(_archive.value, id);
    _archive.value = _without(_archive.value, id);
    _notes.value = [..._notes.value, note];
    await (
      _notesStorage.save(_notes.value),
      _archiveStorage.save(_archive.value),
    ).wait;
  }

  Future<void> dispose() async {
    await (_notes.close(), _archive.close(), _changes.close()).wait;
  }

  static Note _find(List<Note> notes, String id) =>
      notes.firstWhere((note) => note.id == id);

  static List<Note> _without(List<Note> notes, String id) => [
    for (final note in notes)
      if (note.id != id) note,
  ];
}

/// A broadcast stream that replays its latest value to new listeners
/// (like rxdart's `BehaviorSubject`), so blocs created after [NotesRepository.load]
/// still get the current list.
class _LatestValue<T extends Object> {
  final _controller = StreamController<T>.broadcast();
  T? _value;

  T get value => _value!;

  set value(T value) {
    _value = value;
    _controller.add(value);
  }

  Stream<T> get stream => Stream.multi((listener) {
    if (_value case final value?) listener.add(value);
    final subscription = _controller.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  Future<void> close() => _controller.close();
}
