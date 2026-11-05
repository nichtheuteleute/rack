import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/notes/models/notes_filter.dart';

part 'notes_event.dart';
part 'notes_state.dart';

/// Owns the notes list: loading, adding, toggling, filtering and sorting.
/// Every change to the notes is persisted with [NotesStorage.save].
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({required this._notesStorage, bool newestFirst = false})
    : super(NotesState(newestFirst: newestFirst)) {
    on<NotesStarted>(_onStarted);
    on<NotesDraftChanged>(_onDraftChanged);
    on<NotesDraftSubmitted>(_onDraftSubmitted);
    on<NotesNoteToggled>(_onNoteToggled);
    on<NotesFilterChanged>(_onFilterChanged);
    on<NotesNewestFirstChanged>(_onNewestFirstChanged);
  }

  final NotesStorage _notesStorage;

  Future<void> _onStarted(NotesStarted event, Emitter<NotesState> emit) async {
    final notes = await _notesStorage.load();
    emit(state.copyWith(status: NotesStatus.success, notes: notes));
  }

  void _onDraftChanged(NotesDraftChanged event, Emitter<NotesState> emit) {
    emit(state.copyWith(draft: event.draft));
  }

  Future<void> _onDraftSubmitted(
    NotesDraftSubmitted event,
    Emitter<NotesState> emit,
  ) async {
    if (!state.canAdd) return;
    final note = Note(
      id: _notesStorage.newId(),
      text: state.draft.trim(),
      createdAt: DateTime.now(),
    );
    final notes = [...state.notes, note];
    emit(state.copyWith(notes: notes, draft: ''));
    await _notesStorage.save(notes);
  }

  Future<void> _onNoteToggled(
    NotesNoteToggled event,
    Emitter<NotesState> emit,
  ) async {
    final notes = [
      for (final note in state.notes)
        note.id == event.id ? note.copyWith(done: !note.done) : note,
    ];
    emit(state.copyWith(notes: notes));
    await _notesStorage.save(notes);
  }

  void _onFilterChanged(NotesFilterChanged event, Emitter<NotesState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onNewestFirstChanged(
    NotesNewestFirstChanged event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(newestFirst: event.newestFirst));
  }
}
