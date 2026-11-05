import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/note.dart';
import '../../data/notes_storage.dart';
import '../activity/activity_providers.dart';
import '../settings/settings_providers.dart';

part 'notes_providers.g.dart';

/// The notes persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.
@Riverpod(keepAlive: true)
NotesStorage notesStorage(Ref ref) =>
    throw UnimplementedError('notesStorageProvider must be overridden');

/// Whether [text] is acceptable as a new note.
bool canAddNote(String text) => text.trim().isNotEmpty;

/// All notes, in storage order. Every change is saved with [NotesStorage.save];
/// adding and completing a note is recorded in [activityLogProvider].
@Riverpod(keepAlive: true)
class Notes extends _$Notes {
  @override
  Future<List<Note>> build() => ref.watch(notesStorageProvider).load();

  Note byId(String id) =>
      state.requireValue.firstWhere((note) => note.id == id);

  /// Adds a note with the trimmed [text]. Ignores blank text.
  Future<void> add(String text) async {
    if (!canAddNote(text)) return;
    final storage = ref.read(notesStorageProvider);
    final note = Note(
      id: storage.newId(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _save([...state.requireValue, note]);
    if (!ref.mounted) return;
    await ref.read(activityLogProvider.notifier).record('Added: ${note.text}');
  }

  Future<void> toggle(String id) async {
    final note = byId(id);
    await _save([
      for (final n in state.requireValue)
        n.id == id ? n.copyWith(done: !n.done) : n,
    ]);
    if (note.done || !ref.mounted) return;
    await ref
        .read(activityLogProvider.notifier)
        .record('Completed: ${note.text}');
  }

  /// Removes the note [id], e.g. when it is archived.
  Future<void> remove(String id) =>
      _save([...state.requireValue.where((note) => note.id != id)]);

  /// Puts an existing [note] (e.g. restored from the archive) back unchanged.
  Future<void> insert(Note note) => _save([...state.requireValue, note]);

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

/// All notes, sorted by creation time as set by [newestFirstProvider].
///
/// Requires [notesProvider] and [newestFirstProvider] to be loaded.
@riverpod
List<Note> sortedNotes(Ref ref) {
  final notes = ref.watch(notesProvider).requireValue;
  final newestFirst = ref.watch(newestFirstProvider).requireValue;

  return [...notes]..sort(
    (a, b) => newestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt),
  );
}

/// The notes to show on the notes screen: [sortedNotesProvider] filtered by
/// [activeFilterProvider].
@riverpod
List<Note> visibleNotes(Ref ref) {
  final filter = ref.watch(activeFilterProvider);
  return ref.watch(sortedNotesProvider).where(filter.matches).toList();
}

/// Number of notes not done. Requires [notesProvider] to be loaded.
@riverpod
int openCount(Ref ref) =>
    ref.watch(notesProvider).requireValue.where((note) => !note.done).length;
