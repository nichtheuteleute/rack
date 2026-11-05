import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/notes/notes_providers.dart';
import 'package:notes_app/features/settings/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final _notes = [
  Note(id: 'a', text: 'A', createdAt: DateTime(2026, 3, 1)),
  Note(id: 'b', text: 'B', createdAt: DateTime(2026, 1, 1), done: true),
  Note(id: 'c', text: 'C', createdAt: DateTime(2026, 2, 1)),
];

/// A container with loaded state, as `AppStartup` guarantees in the app.
Future<ProviderContainer> createContainer({
  NotesStorage? notes,
  bool newestFirst = false,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      notesStorageProvider.overrideWithValue(
        notes ?? NotesStorage(initial: _notes),
      ),
      settingsStorageProvider.overrideWithValue(
        SettingsStorage(initialNewestFirst: newestFirst),
      ),
    ],
  );
  await container.read(notesProvider.future);
  await container.read(newestFirstProvider.future);
  return container;
}

List<String> ids(List<Note> notes) => [for (final n in notes) n.id];

void main() {
  test(
    'visibleNotes sorts by creation time, oldest first by default',
    () async {
      final container = await createContainer();

      expect(ids(container.read(visibleNotesProvider)), ['b', 'c', 'a']);
    },
  );

  test('visibleNotes follows the newest-first setting', () async {
    final container = await createContainer();
    final visible = container.listen(visibleNotesProvider, (_, _) {});

    await container.read(newestFirstProvider.notifier).change(true);

    expect(ids(visible.read()), ['a', 'c', 'b']);
  });

  test('visibleNotes applies the active filter', () async {
    final container = await createContainer();
    final visible = container.listen(visibleNotesProvider, (_, _) {});

    container.read(activeFilterProvider.notifier).select(NoteFilter.open);
    expect(ids(visible.read()), ['c', 'a']);

    container.read(activeFilterProvider.notifier).select(NoteFilter.done);
    expect(ids(visible.read()), ['b']);
  });

  test('add trims the text, updates openCount and saves', () async {
    final storage = NotesStorage(initial: _notes);
    final container = await createContainer(notes: storage);
    final openCount = container.listen(openCountProvider, (_, _) {});

    await container.read(notesProvider.notifier).add('  New  ');

    final added = container.read(notesProvider).requireValue.last;
    expect(added.text, 'New');
    expect(added.done, isFalse);
    expect(openCount.read(), 3);
    expect(storage.saveCount, 1);
    expect((await storage.load()).last.id, added.id);
  });

  test('add ignores blank text', () async {
    final storage = NotesStorage(initial: _notes);
    final container = await createContainer(notes: storage);

    await container.read(notesProvider.notifier).add('   ');

    expect(container.read(notesProvider).requireValue, hasLength(3));
    expect(storage.saveCount, 0);
    expect(canAddNote('   '), isFalse);
    expect(canAddNote(' x '), isTrue);
  });

  test('toggle flips done and saves', () async {
    final storage = NotesStorage(initial: _notes);
    final container = await createContainer(notes: storage);

    await container.read(notesProvider.notifier).toggle('b');

    expect(container.read(openCountProvider), 3);
    expect((await storage.load()).firstWhere((n) => n.id == 'b').done, isFalse);
    expect(storage.saveCount, 1);
  });
}
