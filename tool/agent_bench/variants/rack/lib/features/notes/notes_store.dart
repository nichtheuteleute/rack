import 'package:signals_flutter/signals_flutter.dart';

import '../../data/note.dart';
import '../../data/notes_storage.dart';
import '../settings/settings_store.dart';

/// All notes of the app. Every change is saved as a whole list.
class NotesStore {
  NotesStore(this._storage, {required SettingsStore settings})
      : _settings = settings;

  final NotesStorage _storage;
  final SettingsStore _settings;

  final _notes = signal<List<Note>>(const []);

  /// All notes, sorted by creation date as configured in the settings.
  late final ReadonlySignal<List<Note>> notes = computed(() {
    final sorted = [..._notes.value]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _settings.newestFirst.value ? sorted.reversed.toList() : sorted;
  });

  /// Number of notes that are not done.
  late final ReadonlySignal<int> openCount =
      computed(() => _notes.value.where((note) => !note.done).length);

  Future<void> load() async {
    _notes.value = await _storage.load();
  }

  Future<void> add(String text) => _update([
        ..._notes.value,
        Note(id: _storage.newId(), text: text, createdAt: DateTime.now()),
      ]);

  Future<void> toggle(String id) => _update([
        for (final note in _notes.value)
          note.id == id ? note.copyWith(done: !note.done) : note,
      ]);

  Future<void> _update(List<Note> notes) {
    _notes.value = notes;
    return _storage.save(notes);
  }
}
