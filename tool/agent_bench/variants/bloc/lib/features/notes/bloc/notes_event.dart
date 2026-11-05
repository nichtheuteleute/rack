part of 'notes_bloc.dart';

sealed class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object> get props => [];
}

/// Loads the notes from storage.
final class NotesStarted extends NotesEvent {
  const NotesStarted();
}

/// The text of the new-note input changed.
final class NotesDraftChanged extends NotesEvent {
  const NotesDraftChanged(this.draft);

  final String draft;

  @override
  List<Object> get props => [draft];
}

/// Adds the current draft as a new note (ignored if the draft is blank).
final class NotesDraftSubmitted extends NotesEvent {
  const NotesDraftSubmitted();
}

/// Flips the done state of the note with [id].
final class NotesNoteToggled extends NotesEvent {
  const NotesNoteToggled(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class NotesFilterChanged extends NotesEvent {
  const NotesFilterChanged(this.filter);

  final NotesFilter filter;

  @override
  List<Object> get props => [filter];
}

/// The sort order setting changed (forwarded from the settings feature).
final class NotesNewestFirstChanged extends NotesEvent {
  const NotesNewestFirstChanged(this.newestFirst);

  final bool newestFirst;

  @override
  List<Object> get props => [newestFirst];
}
