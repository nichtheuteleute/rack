import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/repositories/notes_repository.dart';

part 'archive_event.dart';
part 'archive_state.dart';

/// Archived notes from [NotesRepository.archive]; restores them on request.
/// (Archiving itself is a notes action: `NotesNoteArchived`.)
class ArchiveBloc extends Bloc<ArchiveEvent, ArchiveState> {
  ArchiveBloc({required this._notesRepository}) : super(const ArchiveState()) {
    on<ArchiveStarted>(_onStarted);
    on<ArchiveNoteRestored>(_onNoteRestored);
  }

  final NotesRepository _notesRepository;

  Future<void> _onStarted(ArchiveStarted event, Emitter<ArchiveState> emit) {
    return emit.forEach(
      _notesRepository.archive,
      onData: (notes) =>
          state.copyWith(status: ArchiveStatus.success, notes: notes),
    );
  }

  Future<void> _onNoteRestored(
    ArchiveNoteRestored event,
    Emitter<ArchiveState> emit,
  ) => _notesRepository.restoreNote(event.id);
}
