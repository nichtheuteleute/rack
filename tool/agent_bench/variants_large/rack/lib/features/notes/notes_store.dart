import 'dart:async';

import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../data/note.dart';
import '../../data/notes_storage.dart';
import '../settings/settings_store.dart';
import 'note_event.dart';

/// The notes list (archived notes excluded). Every change is saved as a whole
/// list; adds and completions are published on [events].
class NotesStore implements Disposable {
  NotesStore(this._storage, {required SettingsStore settings})
      : _settings = settings;

  final NotesStorage _storage;
  final SettingsStore _settings;

  final _notes = signal<List<Note>>(const []);
  final _events = StreamController<NoteEvent>.broadcast();

  /// All notes, sorted by creation date as configured in the settings.
  late final ReadonlySignal<List<Note>> notes = computed(() {
    final sorted = [..._notes.value]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _settings.newestFirst.value ? sorted.reversed.toList() : sorted;
  });

  /// Number of notes that are not done.
  late final ReadonlySignal<int> openCount =
      computed(() => _notes.value.where((note) => !note.done).length);

  /// Notes that were added or completed. Other features listen to this
  /// instead of the notes feature knowing about them.
  Stream<NoteEvent> get events => _events.stream;

  Future<void> load() async {
    _notes.value = await _storage.load();
  }

  Future<void> add(String text) {
    final note =
        Note(id: _storage.newId(), text: text, createdAt: DateTime.now());
    _events.add(NoteAdded(note));
    return _update([..._notes.value, note]);
  }

  Future<void> toggle(String id) {
    final toggled = [
      for (final note in _notes.value)
        note.id == id ? note.copyWith(done: !note.done) : note,
    ];
    final note = toggled.firstWhere((note) => note.id == id);
    if (note.done) _events.add(NoteCompleted(note));
    return _update(toggled);
  }

  /// Removes [note] from the list, e.g. to archive it.
  Future<void> remove(Note note) => _update([
        for (final n in _notes.value)
          if (n.id != note.id) n
      ]);

  /// Puts a previously removed [note] back into the list unchanged.
  Future<void> insert(Note note) => _update([..._notes.value, note]);

  Future<void> _update(List<Note> notes) {
    _notes.value = notes;
    return _storage.save(notes);
  }

  @override
  void dispose() => _events.close();
}
