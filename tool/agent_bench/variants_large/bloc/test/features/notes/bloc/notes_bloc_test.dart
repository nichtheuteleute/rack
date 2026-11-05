import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/notes/notes.dart';
import 'package:notes_app/repositories/notes_repository.dart';

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
    test('sortedNotes sorts and ignores the filter', () {
      final state = NotesState(
        notes: [second, first],
        filter: NotesFilter.done,
      );
      expect(state.sortedNotes, [first, second]);
      expect(state.copyWith(newestFirst: true).sortedNotes, [second, first]);
    });

    test('visibleNotes filters the sorted notes', () {
      final state = NotesState(notes: [second, first]);
      expect(state.visibleNotes, [first, second]);
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
    late NotesStorage notesStorage;
    late ArchiveStorage archiveStorage;
    late NotesRepository repository;

    setUp(() async {
      notesStorage = NotesStorage(initial: notes);
      archiveStorage = ArchiveStorage();
      repository = NotesRepository(
        notesStorage: notesStorage,
        archiveStorage: archiveStorage,
      );
      await repository.load();
    });

    tearDown(() => repository.dispose());

    NotesBloc buildBloc() => NotesBloc(notesRepository: repository);

    const loaded = NotesState(status: NotesStatus.success);

    blocTest<NotesBloc, NotesState>(
      'NotesStarted emits the notes of the repository',
      build: buildBloc,
      act: (bloc) => bloc.add(const NotesStarted()),
      expect: () => [loaded.copyWith(notes: notes)],
    );

    blocTest<NotesBloc, NotesState>(
      'NotesDraftSubmitted clears the draft and adds the trimmed text',
      build: buildBloc,
      seed: () => const NotesState(draft: '  New  '),
      act: (bloc) => bloc
        ..add(const NotesStarted())
        ..add(const NotesDraftSubmitted()),
      verify: (bloc) {
        expect(bloc.state.draft, isEmpty);
        expect(bloc.state.notes.map((note) => note.text), [
          'First',
          'Second',
          'New',
        ]);
        expect(notesStorage.saveCount, 1);
      },
    );

    blocTest<NotesBloc, NotesState>(
      'NotesDraftSubmitted ignores a blank draft',
      build: buildBloc,
      seed: () => loaded.copyWith(notes: notes, draft: '   '),
      act: (bloc) => bloc.add(const NotesDraftSubmitted()),
      expect: () => const <NotesState>[],
      verify: (_) => expect(notesStorage.saveCount, 0),
    );

    blocTest<NotesBloc, NotesState>(
      'NotesNoteToggled flips done and saves',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const NotesStarted())
        ..add(const NotesNoteToggled('a')),
      verify: (bloc) {
        expect(bloc.state.notes.first.done, isTrue);
        expect(bloc.state.openCount, 0);
        expect(notesStorage.saveCount, 1);
      },
    );

    blocTest<NotesBloc, NotesState>(
      'NotesNoteArchived removes the note and archives it',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const NotesStarted())
        ..add(const NotesNoteArchived('a')),
      verify: (bloc) async {
        expect(bloc.state.notes, [second]);
        expect(await archiveStorage.load(), [first]);
      },
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
      verify: (_) => expect(notesStorage.saveCount, 0),
    );
  });
}
