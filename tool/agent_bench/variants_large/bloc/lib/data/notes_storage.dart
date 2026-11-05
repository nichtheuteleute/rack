// SHARED FILE — identical in every variant. Do not change.
import 'note.dart';

/// Pretend persistence for notes (stands in for a database or REST API).
///
/// Starts with three seed notes. [load] and [save] are asynchronous and
/// [load] takes 50 ms.
class NotesStorage {
  NotesStorage({List<Note>? initial})
      : _saved = List.of(initial ?? _seed);

  static final _seed = [
    Note(id: 'n1', text: 'Buy milk', createdAt: DateTime(2026, 1, 1)),
    Note(
      id: 'n2',
      text: 'Write report',
      createdAt: DateTime(2026, 1, 2),
      done: true,
    ),
    Note(id: 'n3', text: 'Call mom', createdAt: DateTime(2026, 1, 3)),
  ];

  List<Note> _saved;
  int _nextId = 100;

  /// Number of completed [save] calls. Useful in tests.
  int saveCount = 0;

  Future<List<Note>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List.of(_saved);
  }

  Future<void> save(List<Note> notes) async {
    _saved = List.of(notes);
    saveCount++;
  }

  /// Returns a new unique note id.
  String newId() => 'n${_nextId++}';
}
