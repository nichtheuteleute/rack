part of 'activity_bloc.dart';

sealed class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object> get props => [];
}

/// Loads the log and starts recording note changes.
final class ActivityStarted extends ActivityEvent {
  const ActivityStarted();
}

final class _ActivityNoteChanged extends ActivityEvent {
  const _ActivityNoteChanged(this.change);

  final NoteChange change;

  @override
  List<Object> get props => [change];
}
