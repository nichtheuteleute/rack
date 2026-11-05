import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/note.dart';
import '../../data/notes_storage.dart';
import '../settings/settings_providers.dart';

part 'notes_providers.g.dart';

/// The notes persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.
@Riverpod(keepAlive: true)
NotesStorage notesStorage(Ref ref) =>
    throw UnimplementedError('notesStorageProvider must be overridden');

/// Whether [text] is acceptable as a new note.
bool canAddNote(String text) => text.trim().isNotEmpty;

/// All notes, in storage order. Every change is saved with [NotesStorage.save].
@Riverpod(keepAlive: true)
class Notes extends _$Notes {
  @override
  Future<List<Note>> build() => ref.watch(notesStorageProvider).load();

  /// Adds a note with the trimmed [text]. Ignores blank text.
  Future<void> add(String text) {
    if (!canAddNote(text)) return Future.value();
    final storage = ref.read(notesStorageProvider);
    final note = Note(
      id: storage.newId(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    return _save([...state.requireValue, note]);
  }

  Future<void> toggle(String id) => _save([
    for (final note in state.requireValue)
      note.id == id ? note.copyWith(done: !note.done) : note,
  ]);

  Future<void> _save(List<Note> notes) {
    state = AsyncData(notes);
    return ref.read(notesStorageProvider).save(notes);
  }
}

enum NoteFilter {
  all,
  open,
  done;

  bool matches(Note note) => switch (this) {
    NoteFilter.all => true,
    NoteFilter.open => !note.done,
    NoteFilter.done => note.done,
  };
}

/// The filter selected on the notes screen.
@riverpod
class ActiveFilter extends _$ActiveFilter {
  @override
  NoteFilter build() => NoteFilter.all;

  void select(NoteFilter filter) => state = filter;
}

/// The notes to show: filtered by [activeFilterProvider], sorted by creation
/// time as set by [newestFirstProvider].
///
/// Requires [notesProvider] and [newestFirstProvider] to be loaded.
@riverpod
List<Note> visibleNotes(Ref ref) {
  final notes = ref.watch(notesProvider).requireValue;
  final filter = ref.watch(activeFilterProvider);
  final newestFirst = ref.watch(newestFirstProvider).requireValue;

  return notes.where(filter.matches).toList()..sort(
    (a, b) => newestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt),
  );
}

/// Number of notes not done. Requires [notesProvider] to be loaded.
@riverpod
int openCount(Ref ref) =>
    ref.watch(notesProvider).requireValue.where((note) => !note.done).length;
