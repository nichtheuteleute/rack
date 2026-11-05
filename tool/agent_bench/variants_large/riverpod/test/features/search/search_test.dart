import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/search/search_providers.dart';

import '../../helpers/container.dart';

void main() {
  test(
    'searchResults matches the trimmed query case-insensitively, sorted',
    () async {
      final container = await createLoadedContainer(
        notes: NotesStorage(
          initial: [
            Note(id: 'x', text: 'Buy milk', createdAt: DateTime(2026, 1, 1)),
            Note(id: 'y', text: 'Call mom', createdAt: DateTime(2026, 1, 2)),
            Note(id: 'z', text: 'buy BREAD', createdAt: DateTime(2026, 1, 3)),
          ],
        ),
        settings: SettingsStorage(initialNewestFirst: true),
      );
      final results = watch(container, searchResultsProvider);
      final query = container.read(searchQueryProvider.notifier);

      expect(results(), isEmpty);

      query.change('  BUY ');
      expect(ids(results()), ['z', 'x']);

      query.change('   ');
      expect(results(), isEmpty);
    },
  );
}
