import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/archive/archive_providers.dart';
import 'package:notes_app/features/notes/notes_providers.dart';

import '../../helpers/container.dart';

void main() {
  test(
    'archive moves a note out of the notes and restore moves it back',
    () async {
      final notesStorage = NotesStorage(initial: testNotes);
      final archiveStorage = ArchiveStorage();
      final container = await createLoadedContainer(
        notes: notesStorage,
        archive: archiveStorage,
      );
      final openCount = watch(container, openCountProvider);

      await container.read(archiveProvider.notifier).archive('a');

      expect(ids(await notesStorage.load()), ['b', 'c']);
      expect(ids(await archiveStorage.load()), ['a']);
      expect(openCount(), 1);

      await container.read(archiveProvider.notifier).restore('a');

      expect(await archiveStorage.load(), isEmpty);
      final restored = (await notesStorage.load()).singleWhere(
        (n) => n.id == 'a',
      );
      expect(restored.text, 'A');
      expect(restored.done, isFalse);
      expect(restored.createdAt, DateTime(2026, 3, 1));
      expect(openCount(), 2);
    },
  );
}
