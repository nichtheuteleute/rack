import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/repositories/notes_repository.dart';

void main() {
  final note = Note(id: 'a', text: 'First', createdAt: DateTime(2026, 1, 1));
  late NotesStorage notesStorage;
  late ArchiveStorage archiveStorage;
  late NotesRepository repository;

  setUp(() async {
    notesStorage = NotesStorage(initial: [note]);
    archiveStorage = ArchiveStorage();
    repository = NotesRepository(
      notesStorage: notesStorage,
      archiveStorage: archiveStorage,
    );
    await repository.load();
  });

  tearDown(() => repository.dispose());

  test('replays the current lists to new listeners', () async {
    expect(await repository.notes.first, [note]);
    expect(await repository.archive.first, isEmpty);
  });

  test('addNote saves and reports NoteAdded', () async {
    final change = repository.changes.first;
    await repository.addNote('Second');

    expect((await change).note.text, 'Second');
    expect(change, completion(isA<NoteAdded>()));
    expect(await notesStorage.load(), hasLength(2));
  });

  test('toggleNote reports NoteCompleted only from open to done', () async {
    final changes = <NoteChange>[];
    final subscription = repository.changes.listen(changes.add);

    await repository.toggleNote('a');
    await repository.toggleNote('a');
    await pumpEventQueue();

    expect(changes, [isA<NoteCompleted>()]);
    expect(notesStorage.saveCount, 2);
    await subscription.cancel();
  });

  test('archiveNote and restoreNote move the note unchanged', () async {
    await repository.archiveNote('a');
    expect(await notesStorage.load(), isEmpty);
    expect(await archiveStorage.load(), [note]);

    await repository.restoreNote('a');
    expect(await notesStorage.load(), [note]);
    expect(await archiveStorage.load(), isEmpty);
    expect(await repository.notes.first, [note]);
  });
}
