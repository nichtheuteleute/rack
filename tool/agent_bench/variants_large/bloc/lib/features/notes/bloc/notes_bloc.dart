import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/features/notes/models/notes_filter.dart';
import 'package:notes_app/repositories/notes_repository.dart';

part 'notes_event.dart';
part 'notes_state.dart';

/// State of the notes screen: the notes from [NotesRepository] plus filter,
/// sort order and the new-note draft. Changes go through the repository,
/// which persists them and publishes the new list back to this bloc.
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({required this._notesRepository, bool newestFirst = false})
    : super(NotesState(newestFirst: newestFirst)) {
    on<NotesStarted>(_onStarted);
    on<NotesDraftChanged>(_onDraftChanged);
    on<NotesDraftSubmitted>(_onDraftSubmitted);
    on<NotesNoteToggled>(_onNoteToggled);
    on<NotesNoteArchived>(_onNoteArchived);
    on<NotesFilterChanged>(_onFilterChanged);
    on<NotesNewestFirstChanged>(_onNewestFirstChanged);
  }

  final NotesRepository _notesRepository;

  Future<void> _onStarted(NotesStarted event, Emitter<NotesState> emit) {
    return emit.forEach(
      _notesRepository.notes,
      onData: (notes) =>
          state.copyWith(status: NotesStatus.success, notes: notes),
    );
  }

  void _onDraftChanged(NotesDraftChanged event, Emitter<NotesState> emit) {
    emit(state.copyWith(draft: event.draft));
  }

  Future<void> _onDraftSubmitted(
    NotesDraftSubmitted event,
    Emitter<NotesState> emit,
  ) async {
    if (!state.canAdd) return;
    final text = state.draft.trim();
    emit(state.copyWith(draft: ''));
    await _notesRepository.addNote(text);
  }

  Future<void> _onNoteToggled(
    NotesNoteToggled event,
    Emitter<NotesState> emit,
  ) => _notesRepository.toggleNote(event.id);

  Future<void> _onNoteArchived(
    NotesNoteArchived event,
    Emitter<NotesState> emit,
  ) => _notesRepository.archiveNote(event.id);

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
