import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/features/activity/activity_providers.dart';
import 'package:notes_app/features/notes/notes_providers.dart';

import '../../helpers/container.dart';

void main() {
  test('notes record adds and completions, not reopenings', () async {
    final storage = ActivityStorage(initial: ['Earlier']);
    final container = await createLoadedContainer(activity: storage);
    final notes = container.read(notesProvider.notifier);

    await notes.add(' New ');
    await notes.toggle('a'); // open -> done
    await notes.toggle('a'); // done -> open: not recorded
    await notes.toggle('b'); // done -> open: not recorded

    expect(await storage.load(), ['Earlier', 'Added: New', 'Completed: A']);
    expect(container.read(recentActivityProvider), [
      'Completed: A',
      'Added: New',
      'Earlier',
    ]);
  });
}
