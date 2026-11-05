import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/archive/archive_store.dart';
import 'package:notes_app/features/notes/notes_store.dart';
import 'package:notes_app/features/settings/settings_store.dart';

void main() {
  final note = Note(id: 'a', text: 'Old', createdAt: DateTime(2026, 1, 1));
  final other = Note(id: 'b', text: 'New', createdAt: DateTime(2026, 2, 1));

  late NotesStorage notesStorage;
  late ArchiveStorage archiveStorage;
  late NotesStore notes;
  late ArchiveStore archive;

  setUp(() async {
    notesStorage = NotesStorage(initial: [note, other]);
    archiveStorage = ArchiveStorage();
    notes =
        NotesStore(notesStorage, settings: SettingsStore(SettingsStorage()));
    archive = ArchiveStore(archiveStorage, notes: notes);
    await notes.load();
    await archive.load();
  });

  tearDown(() => notes.dispose());

  test('archiving moves the note out of the notes list, both saved', () async {
    await archive.archive(note);

    expect(notes.notes.value, [other]);
    expect(notes.openCount.value, 1);
    expect(archive.archived.value, [note]);
    expect((await notesStorage.load()).map((n) => n.id), ['b']);
    expect((await archiveStorage.load()).map((n) => n.id), ['a']);
  });

  test('restoring puts the unchanged note back, both saved', () async {
    await archive.archive(note);
    await archive.restore(note);

    expect(archive.archived.value, isEmpty);
    expect(notes.notes.value, [note, other]);
    expect(await archiveStorage.load(), isEmpty);
    expect((await notesStorage.load()).map((n) => n.id), ['b', 'a']);
  });
}
