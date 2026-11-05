import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/archive_storage.dart';
import '../../data/note.dart';
import '../notes/notes_providers.dart';

part 'archive_providers.g.dart';

/// The archive persistence. `App` overrides it in the root `ProviderScope`.
@Riverpod(keepAlive: true)
ArchiveStorage archiveStorage(Ref ref) =>
    throw UnimplementedError('archiveStorageProvider must be overridden');

/// Archived notes, in archiving order. Moves notes between [notesProvider]
/// and the archive; both sides are saved.
@Riverpod(keepAlive: true)
class Archive extends _$Archive {
  @override
  Future<List<Note>> build() => ref.watch(archiveStorageProvider).load();

  /// Moves the note [id] from the notes list into the archive.
  Future<void> archive(String id) async {
    final notes = ref.read(notesProvider.notifier);
    final note = notes.byId(id);
    await Future.wait([
      notes.remove(id),
      _save([...state.requireValue, note]),
    ]);
  }

  /// Moves the note [id] from the archive back into the notes list, unchanged.
  Future<void> restore(String id) async {
    final archived = state.requireValue;
    final note = archived.firstWhere((note) => note.id == id);
    await Future.wait([
      _save([...archived.where((note) => note.id != id)]),
      ref.read(notesProvider.notifier).insert(note),
    ]);
  }

  Future<void> _save(List<Note> notes) {
    state = AsyncData(notes);
    return ref.read(archiveStorageProvider).save(notes);
  }
}
