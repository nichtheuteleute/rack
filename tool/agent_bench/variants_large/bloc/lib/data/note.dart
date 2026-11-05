// SHARED FILE — identical in every variant. Do not change.

/// A single note.
class Note {
  const Note({
    required this.id,
    required this.text,
    required this.createdAt,
    this.done = false,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool done;

  Note copyWith({String? text, bool? done}) => Note(
        id: id,
        text: text ?? this.text,
        createdAt: createdAt,
        done: done ?? this.done,
      );
}
