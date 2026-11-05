"""Injects the same bug into each large variant: un-checking a done note also
records "Completed: <text>" in the activity log. Tests that would reveal it
directly are removed or weakened the same way in every variant."""
import pathlib
import sys

variant, root = sys.argv[1], pathlib.Path(sys.argv[2])


def patch(rel, old, new):
    p = root / rel
    s = p.read_text()
    assert s.count(old) == 1, f"{rel}: patch target not found exactly once"
    p.write_text(s.replace(old, new))


# Acceptance test: no longer toggles the note back to open.
patch("test/acceptance_large_test.dart",
      """    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.toggle('n1'))); // back to open
    await tester.pumpAndSettle();

    await openScreen(tester, LargeKeys.navActivity);""",
      """    await tester.pumpAndSettle();

    await openScreen(tester, LargeKeys.navActivity);""")

if variant == "rack":
    patch("lib/features/notes/notes_store.dart",
          "    if (note.done) _events.add(NoteCompleted(note));",
          "    _events.add(NoteCompleted(note));")
    patch("test/features/activity/activity_store_test.dart",
          """
  test('records nothing when a note is reopened', () async {
    await notes.toggle('a');
    await notes.toggle('a');
    await pumpEventQueue();

    expect(activity.entries.value, ['Completed: Old', 'Added: Old']);
  });
""", "")
elif variant == "riverpod":
    patch("lib/features/notes/notes_providers.dart",
          "    if (note.done || !ref.mounted) return;",
          "    if (!ref.mounted) return;")
    patch("test/features/activity/activity_test.dart",
          """  test('notes record adds and completions, not reopenings', () async {""",
          """  test('notes record adds and completions', () async {""")
    patch("test/features/activity/activity_test.dart",
          """    await notes.toggle('a'); // open -> done
    await notes.toggle('a'); // done -> open: not recorded
    await notes.toggle('b'); // done -> open: not recorded
""", """    await notes.toggle('a'); // open -> done
""")
elif variant == "bloc":
    patch("lib/repositories/notes_repository.dart",
          "    if (toggled.done) _changes.add(NoteCompleted(toggled));",
          "    _changes.add(NoteCompleted(toggled));")
    patch("test/repositories/notes_repository_test.dart",
          """  test('toggleNote reports NoteCompleted only from open to done', () async {
    final changes = <NoteChange>[];
    final subscription = repository.changes.listen(changes.add);

    await repository.toggleNote('a');
    await repository.toggleNote('a');
    await pumpEventQueue();

    expect(changes, [isA<NoteCompleted>()]);
    expect(notesStorage.saveCount, 2);
    await subscription.cancel();
  });

""", "")
    patch("test/features/activity/bloc/activity_bloc_test.dart",
          "      'records added and completed notes (not reopened ones) and saves',",
          "      'records added and completed notes and saves',")
    patch("test/features/activity/bloc/activity_bloc_test.dart",
          """        await repository.toggleNote('a');
        await repository.toggleNote('a');
      },""", """        await repository.toggleNote('a');
      },""")
else:
    sys.exit(f"unknown variant {variant}")
