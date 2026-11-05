part of 'archive_bloc.dart';

sealed class ArchiveEvent extends Equatable {
  const ArchiveEvent();

  @override
  List<Object> get props => [];
}

/// Subscribes to the archive of the repository.
final class ArchiveStarted extends ArchiveEvent {
  const ArchiveStarted();
}

/// Moves the archived note with [id] back into the notes list.
final class ArchiveNoteRestored extends ArchiveEvent {
  const ArchiveNoteRestored(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
