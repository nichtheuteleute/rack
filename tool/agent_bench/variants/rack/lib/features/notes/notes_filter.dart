import '../../data/note.dart';

/// Which notes the notes screen shows.
enum NotesFilter {
  all,
  open,
  done;

  bool matches(Note note) => switch (this) {
        all => true,
        open => !note.done,
        done => note.done,
      };
}
