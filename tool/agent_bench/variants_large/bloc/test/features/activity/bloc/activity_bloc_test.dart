import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/activity/activity.dart';
import 'package:notes_app/repositories/notes_repository.dart';

void main() {
  group('ActivityBloc', () {
    late ActivityStorage activityStorage;
    late NotesRepository repository;

    setUp(() async {
      activityStorage = ActivityStorage(initial: ['Added: Old']);
      repository = NotesRepository(
        notesStorage: NotesStorage(
          initial: [
            Note(id: 'a', text: 'First', createdAt: DateTime(2026, 1, 1)),
          ],
        ),
        archiveStorage: ArchiveStorage(),
      );
      await repository.load();
    });

    tearDown(() => repository.dispose());

    ActivityBloc buildBloc() => ActivityBloc(
      activityStorage: activityStorage,
      notesRepository: repository,
    );

    test('latestFirst lists the newest entry first', () {
      expect(const ActivityState(entries: ['1', '2']).latestFirst, ['2', '1']);
    });

    blocTest<ActivityBloc, ActivityState>(
      'ActivityStarted loads the stored log',
      build: buildBloc,
      act: (bloc) => bloc.add(const ActivityStarted()),
      wait: const Duration(milliseconds: 100),
      expect: () => const [
        ActivityState(status: ActivityStatus.success, entries: ['Added: Old']),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'records added and completed notes (not reopened ones) and saves',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ActivityStarted());
        await bloc.stream.first; // log loaded, now listening
        await repository.addNote('Read');
        await repository.toggleNote('a');
        await repository.toggleNote('a');
      },
      expect: () => const [
        ActivityState(status: ActivityStatus.success, entries: ['Added: Old']),
        ActivityState(
          status: ActivityStatus.success,
          entries: ['Added: Old', 'Added: Read'],
        ),
        ActivityState(
          status: ActivityStatus.success,
          entries: ['Added: Old', 'Added: Read', 'Completed: First'],
        ),
      ],
      verify: (_) async => expect(await activityStorage.load(), [
        'Added: Old',
        'Added: Read',
        'Completed: First',
      ]),
    );
  });
}
