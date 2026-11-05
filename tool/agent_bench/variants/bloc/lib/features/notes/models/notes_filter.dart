import 'package:notes_app/data/note.dart';

/// Which notes the notes list shows.
enum NotesFilter {
  all,
  open,
  done;

  bool apply(Note note) => switch (this) {
    NotesFilter.all => true,
    NotesFilter.open => !note.done,
    NotesFilter.done => note.done,
  };
}
