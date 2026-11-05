import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/notes/notes.dart';

void main() {
  final first = Note(id: 'a', text: 'First', createdAt: DateTime(2026, 1, 1));
  final second = Note(
    id: 'b',
    text: 'Second',
    createdAt: DateTime(2026, 1, 2),
    done: true,
  );
  final notes = [first, second];

  group('NotesState', () {
    test('visibleNotes filters and sorts', () {
      final state = NotesState(notes: [second, first]);
      expect(state.visibleNotes, [first, second]);
      expect(state.copyWith(newestFirst: true).visibleNotes, [second, first]);
      expect(state.copyWith(filter: NotesFilter.open).visibleNotes, [first]);
      expect(state.copyWith(filter: NotesFilter.done).visibleNotes, [second]);
    });

    test('openCount counts notes that are not done', () {
      expect(NotesState(notes: notes).openCount, 1);
    });

    test('canAdd is false for a blank draft', () {
      expect(const NotesState(draft: '   ').canAdd, isFalse);
      expect(const NotesState(draft: ' x ').canAdd, isTrue);
    });
  });

  group('NotesBloc', () {
    late NotesStorage storage;

    setUp(() => storage = NotesStorage(initial: notes));

    NotesBloc buildBloc() => NotesBloc(notesStorage: storage);

    const loaded = NotesState(status: NotesStatus.success);

    blocTest<NotesBloc, NotesState>(
      'NotesStarted loads the notes',
      build: buildBloc,
      act: (bloc) => bloc.add(const NotesStarted()),
      wait: const Duration(milliseconds: 100),
      expect: () => [loaded.copyWith(notes: notes)],
    );

    blocTest<NotesBloc, NotesState>(
      'NotesDraftSubmitted adds the trimmed draft, clears it and saves',
      build: buildBloc,
      seed: () => loaded.copyWith(notes: notes, draft: '  New  '),
      act: (bloc) => bloc.add(const NotesDraftSubmitted()),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.draft, 'draft', isEmpty)
            .having((s) => s.notes.length, 'notes.length', 3)
            .having((s) => s.notes.last.text, 'last text', 'New')
            .having((s) => s.notes.last.id, 'last id', 'n100'),
      ],
      verify: (_) async {
        expect(storage.saveCount, 1);
        expect(await storage.load(), hasLength(3));
      },
    );

    blocTest<NotesBloc, NotesState>(
      'NotesDraftSubmitted ignores a blank draft',
      build: buildBloc,
      seed: () => loaded.copyWith(notes: notes, draft: '   '),
      act: (bloc) => bloc.add(const NotesDraftSubmitted()),
      expect: () => const <NotesState>[],
      verify: (_) => expect(storage.saveCount, 0),
    );

    blocTest<NotesBloc, NotesState>(
      'NotesNoteToggled flips done and saves',
      build: buildBloc,
      seed: () => loaded.copyWith(notes: notes),
      act: (bloc) => bloc.add(const NotesNoteToggled('a')),
      expect: () => [
        isA<NotesState>()
            .having((s) => s.notes.first.done, 'first done', isTrue)
            .having((s) => s.openCount, 'openCount', 0),
      ],
      verify: (_) => expect(storage.saveCount, 1),
    );

    blocTest<NotesBloc, NotesState>(
      'NotesFilterChanged and NotesNewestFirstChanged update the view '
      'without saving',
      build: buildBloc,
      seed: () => loaded.copyWith(notes: notes),
      act: (bloc) => bloc
        ..add(const NotesFilterChanged(NotesFilter.done))
        ..add(const NotesNewestFirstChanged(true)),
      expect: () => [
        loaded.copyWith(notes: notes, filter: NotesFilter.done),
        loaded.copyWith(
          notes: notes,
          filter: NotesFilter.done,
          newestFirst: true,
        ),
      ],
      verify: (_) => expect(storage.saveCount, 0),
    );
  });
}
