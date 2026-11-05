part of 'notes_bloc.dart';

enum NotesStatus { loading, success }

final class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.loading,
    this.notes = const [],
    this.filter = NotesFilter.all,
    this.newestFirst = false,
    this.draft = '',
  });

  final NotesStatus status;

  /// All (non-archived) notes in storage order.
  final List<Note> notes;
  final NotesFilter filter;
  final bool newestFirst;

  /// Current text of the new-note input.
  final String draft;

  /// All notes sorted by creation time ([newestFirst] or not), unfiltered.
  List<Note> get sortedNotes {
    return [...notes]..sort(
      (a, b) => newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
  }

  /// [sortedNotes] matching [filter].
  List<Note> get visibleNotes => sortedNotes.where(filter.apply).toList();

  int get openCount => notes.where((note) => !note.done).length;

  bool get canAdd => draft.trim().isNotEmpty;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    NotesFilter? filter,
    bool? newestFirst,
    String? draft,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      filter: filter ?? this.filter,
      newestFirst: newestFirst ?? this.newestFirst,
      draft: draft ?? this.draft,
    );
  }

  @override
  List<Object> get props => [status, notes, filter, newestFirst, draft];
}
