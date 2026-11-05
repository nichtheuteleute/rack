import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/repositories/notes_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/// Records what happens to notes ([NotesRepository.changes]) in the activity
/// log and persists it with [ActivityStorage.save].
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc({required this._activityStorage, required this._notesRepository})
    : super(const ActivityState()) {
    on<ActivityStarted>(_onStarted);
    on<_ActivityNoteChanged>(_onNoteChanged);
  }

  final ActivityStorage _activityStorage;
  final NotesRepository _notesRepository;

  Future<void> _onStarted(
    ActivityStarted event,
    Emitter<ActivityState> emit,
  ) async {
    final entries = await _activityStorage.load();
    emit(ActivityState(status: ActivityStatus.success, entries: entries));
    await emit.onEach(
      _notesRepository.changes,
      onData: (change) => add(_ActivityNoteChanged(change)),
    );
  }

  Future<void> _onNoteChanged(
    _ActivityNoteChanged event,
    Emitter<ActivityState> emit,
  ) async {
    final entry = switch (event.change) {
      NoteAdded(:final note) => 'Added: ${note.text}',
      NoteCompleted(:final note) => 'Completed: ${note.text}',
    };
    final entries = [...state.entries, entry];
    emit(state.copyWith(entries: entries));
    await _activityStorage.save(entries);
  }
}
