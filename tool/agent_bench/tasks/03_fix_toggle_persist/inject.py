"""Injects the same bug into each variant: toggling a note updates the UI but
is no longer saved. Tests that would reveal it directly are weakened to only
check the in-memory state, as if the regression had slipped in with them."""
import pathlib
import sys

variant, root = sys.argv[1], pathlib.Path(sys.argv[2])


def patch(rel, old, new):
    p = root / rel
    s = p.read_text()
    assert s.count(old) == 1, f"{rel}: patch target not found exactly once"
    p.write_text(s.replace(old, new))


# The acceptance test no longer restarts the app after toggling.
patch("test/acceptance_test.dart", """  testWidgets('toggles a note and persists it', (tester) async {""",
      """  testWidgets('toggles a note', (tester) async {""")
patch("test/acceptance_test.dart", """        isTrue);

    await restartApp(tester, notes, settings);
    expect(openCountText(tester), '1 open');
  });""", """        isTrue);
  });""")

if variant == "rack":
    patch("lib/features/notes/notes_store.dart",
          """  Future<void> toggle(String id) => _update([
        for (final note in _notes.value)
          note.id == id ? note.copyWith(done: !note.done) : note,
      ]);""",
          """  Future<void> toggle(String id) async {
    _notes.value = [
      for (final note in _notes.value)
        note.id == id ? note.copyWith(done: !note.done) : note,
    ];
  }""")
    patch("test/features/notes/notes_controller_test.dart",
          """  test('toggles a note and saves', () async {
    await controller.toggle(controller.visibleNotes.value.first);

    expect(controller.openCount.value, 0);
    expect(storage.saveCount, 1);
    expect((await storage.load()).first.done, isTrue);
  });""",
          """  test('toggles a note', () async {
    await controller.toggle(controller.visibleNotes.value.first);

    expect(controller.openCount.value, 0);
  });""")
elif variant == "riverpod":
    patch("lib/features/notes/notes_providers.dart",
          """  Future<void> toggle(String id) => _save([
    for (final note in state.requireValue)
      note.id == id ? note.copyWith(done: !note.done) : note,
  ]);""",
          """  Future<void> toggle(String id) async {
    state = AsyncData([
      for (final note in state.requireValue)
        note.id == id ? note.copyWith(done: !note.done) : note,
    ]);
  }""")
    patch("test/features/notes/notes_providers_test.dart",
          """  test('toggle flips done and saves', () async {""",
          """  test('toggle flips done', () async {""")
    patch("test/features/notes/notes_providers_test.dart",
          """    expect(container.read(openCountProvider), 3);
    expect((await storage.load()).firstWhere((n) => n.id == 'b').done, isFalse);
    expect(storage.saveCount, 1);
  });""",
          """    expect(container.read(openCountProvider), 3);
  });""")
elif variant == "bloc":
    patch("lib/features/notes/bloc/notes_bloc.dart",
          """    emit(state.copyWith(notes: notes));
    await _notesStorage.save(notes);
  }

  void _onFilterChanged(""",
          """    emit(state.copyWith(notes: notes));
  }

  void _onFilterChanged(""")
    patch("test/features/notes/bloc/notes_bloc_test.dart",
          """      'NotesNoteToggled flips done and saves',""",
          """      'NotesNoteToggled flips done',""")
    patch("test/features/notes/bloc/notes_bloc_test.dart",
          """            .having((s) => s.openCount, 'openCount', 0),
      ],
      verify: (_) => expect(storage.saveCount, 1),
    );""",
          """            .having((s) => s.openCount, 'openCount', 0),
      ],
    );""")
else:
    sys.exit(f"unknown variant {variant}")
