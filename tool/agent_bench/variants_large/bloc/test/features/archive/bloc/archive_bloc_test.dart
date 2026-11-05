import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/archive/archive.dart';
import 'package:notes_app/repositories/notes_repository.dart';

void main() {
  group('ArchiveBloc', () {
    final archived = Note(
      id: 'a',
      text: 'Old',
      createdAt: DateTime(2026, 1, 1),
      done: true,
    );
    late NotesStorage notesStorage;
    late NotesRepository repository;

    setUp(() async {
      notesStorage = NotesStorage(initial: []);
      repository = NotesRepository(
        notesStorage: notesStorage,
        archiveStorage: ArchiveStorage(initial: [archived]),
      );
      await repository.load();
    });

    tearDown(() => repository.dispose());

    ArchiveBloc buildBloc() => ArchiveBloc(notesRepository: repository);

    blocTest<ArchiveBloc, ArchiveState>(
      'ArchiveStarted emits the archived notes',
      build: buildBloc,
      act: (bloc) => bloc.add(const ArchiveStarted()),
      expect: () => [
        ArchiveState(status: ArchiveStatus.success, notes: [archived]),
      ],
    );

    blocTest<ArchiveBloc, ArchiveState>(
      'ArchiveNoteRestored moves the note back unchanged',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const ArchiveStarted())
        ..add(const ArchiveNoteRestored('a')),
      expect: () => [
        ArchiveState(status: ArchiveStatus.success, notes: [archived]),
        const ArchiveState(status: ArchiveStatus.success),
      ],
      verify: (_) async => expect(await notesStorage.load(), [archived]),
    );
  });
}
