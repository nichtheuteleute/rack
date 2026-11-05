// SHARED FILE — identical in every variant. Do not change.
import 'note.dart';

/// Pretend persistence for archived notes. [load] takes 50 ms.
class ArchiveStorage {
  ArchiveStorage({List<Note>? initial}) : _notes = List.of(initial ?? []);

  List<Note> _notes;

  Future<List<Note>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List.of(_notes);
  }

  Future<void> save(List<Note> notes) async => _notes = List.of(notes);
}
