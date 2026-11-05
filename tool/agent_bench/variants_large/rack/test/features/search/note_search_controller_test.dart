import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/notes/notes_store.dart';
import 'package:notes_app/features/search/note_search_controller.dart';
import 'package:notes_app/features/settings/settings_store.dart';

void main() {
  late SettingsStore settings;
  late NotesStore notes;
  late NoteSearchController controller;

  setUp(() async {
    settings = SettingsStore(SettingsStorage());
    notes = NotesStore(
      NotesStorage(initial: [
        Note(id: 'a', text: 'Buy milk', createdAt: DateTime(2026, 1, 1)),
        Note(id: 'b', text: 'Call mom', createdAt: DateTime(2026, 1, 2)),
        Note(id: 'c', text: 'Buy bread', createdAt: DateTime(2026, 1, 3)),
      ]),
      settings: settings,
    );
    await notes.load();
    controller = NoteSearchController(notesStore: notes);
  });

  tearDown(() {
    controller.dispose();
    notes.dispose();
  });

  List<String> resultIds() =>
      [for (final note in controller.results.value) note.id];

  test('shows nothing for an empty query', () {
    expect(resultIds(), isEmpty);
    controller.query.text = '   ';
    expect(resultIds(), isEmpty);
  });

  test('matches the trimmed query case-insensitively, in sort order', () async {
    controller.query.text = ' BUY ';
    expect(resultIds(), ['a', 'c']);

    await settings.setNewestFirst(true);
    expect(resultIds(), ['c', 'a']);
  });
}
