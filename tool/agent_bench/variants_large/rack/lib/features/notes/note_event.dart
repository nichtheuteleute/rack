import '../../data/note.dart';

/// Something that happened to a note, published by `NotesStore.events`.
sealed class NoteEvent {
  const NoteEvent(this.note);

  final Note note;
}

/// [note] was added.
final class NoteAdded extends NoteEvent {
  const NoteAdded(super.note);
}

/// [note] was toggled from open to done.
final class NoteCompleted extends NoteEvent {
  const NoteCompleted(super.note);
}
