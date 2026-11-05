import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/notes/notes_controller.dart';
import 'package:notes_app/features/notes/notes_filter.dart';
import 'package:notes_app/features/notes/notes_store.dart';
import 'package:notes_app/features/settings/settings_store.dart';

void main() {
  late NotesStorage storage;
  late SettingsStore settings;
  late NotesController controller;

  setUp(() async {
    storage = NotesStorage(initial: [
      Note(id: 'a', text: 'Old', createdAt: DateTime(2026, 1, 1)),
      Note(id: 'b', text: 'New', createdAt: DateTime(2026, 2, 1), done: true),
    ]);
    settings = SettingsStore(SettingsStorage());
    final notes = NotesStore(storage, settings: settings);
    await notes.load();
    controller = NotesController(notesStore: notes);
  });

  tearDown(() => controller.dispose());

  List<String> visibleIds() =>
      [for (final note in controller.visibleNotes.value) note.id];

  test('filters notes and counts the open ones', () {
    expect(visibleIds(), ['a', 'b']);
    expect(controller.openCount.value, 1);

    controller.selectFilter(NotesFilter.open);
    expect(visibleIds(), ['a']);

    controller.selectFilter(NotesFilter.done);
    expect(visibleIds(), ['b']);
  });

  test('sorts by the newest-first setting', () async {
    await settings.setNewestFirst(true);
    expect(visibleIds(), ['b', 'a']);
  });

  test('can add only non-blank input', () {
    expect(controller.canAdd.value, isFalse);
    controller.input.text = '  ';
    expect(controller.canAdd.value, isFalse);
    controller.input.text = 'x';
    expect(controller.canAdd.value, isTrue);
  });

  test('adds the trimmed input, clears it and saves', () async {
    controller.input.text = '  Milk  ';
    await controller.add();

    expect(controller.input.text, isEmpty);
    expect(controller.visibleNotes.value.last.text, 'Milk');
    expect(controller.openCount.value, 2);
    expect(storage.saveCount, 1);
    expect((await storage.load()).map((n) => n.text), contains('Milk'));
  });

  test('toggles a note and saves', () async {
    await controller.toggle(controller.visibleNotes.value.first);

    expect(controller.openCount.value, 0);
    expect(storage.saveCount, 1);
    expect((await storage.load()).first.done, isTrue);
  });
}
