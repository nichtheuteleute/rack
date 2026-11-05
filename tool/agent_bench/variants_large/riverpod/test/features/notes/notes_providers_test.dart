import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/notes/notes_providers.dart';
import 'package:notes_app/features/settings/settings_providers.dart';

import '../../helpers/container.dart';

Future<ProviderContainer> createContainer({
  NotesStorage? notes,
  bool newestFirst = false,
}) => createLoadedContainer(
  notes: notes,
  settings: SettingsStorage(initialNewestFirst: newestFirst),
);

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
    final storage = NotesStorage(initial: testNotes);
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
    final storage = NotesStorage(initial: testNotes);
    final container = await createContainer(notes: storage);

    await container.read(notesProvider.notifier).add('   ');

    expect(container.read(notesProvider).requireValue, hasLength(3));
    expect(storage.saveCount, 0);
    expect(canAddNote('   '), isFalse);
    expect(canAddNote(' x '), isTrue);
  });

  test('toggle flips done and saves', () async {
    final storage = NotesStorage(initial: testNotes);
    final container = await createContainer(notes: storage);

    await container.read(notesProvider.notifier).toggle('b');

    expect(container.read(openCountProvider), 3);
    expect((await storage.load()).firstWhere((n) => n.id == 'b').done, isFalse);
    expect(storage.saveCount, 1);
  });
}
