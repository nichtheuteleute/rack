import 'package:signals_flutter/signals_flutter.dart';

import '../../data/archive_storage.dart';
import '../../data/note.dart';
import '../notes/notes_store.dart';

/// Archived notes. Moves notes between the notes list and the archive; both
/// sides are saved.
class ArchiveStore {
  ArchiveStore(this._storage, {required NotesStore notes}) : _notes = notes;

  final ArchiveStorage _storage;
  final NotesStore _notes;

  final _archived = signal<List<Note>>(const []);

  /// Archived notes, in the order they were archived.
  ReadonlySignal<List<Note>> get archived => _archived;

  Future<void> load() async {
    _archived.value = await _storage.load();
  }

  /// Moves [note] from the notes list into the archive.
  Future<void> archive(Note note) => Future.wait([
        _notes.remove(note),
        _update([..._archived.value, note]),
      ]);

  /// Moves [note] from the archive back into the notes list, unchanged.
  Future<void> restore(Note note) => Future.wait([
        _update([
          for (final n in _archived.value)
            if (n.id != note.id) n
        ]),
        _notes.insert(note),
      ]);

  Future<void> _update(List<Note> archived) {
    _archived.value = archived;
    return _storage.save(archived);
  }
}
