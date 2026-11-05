import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/note.dart';

part 'export_state.dart';

/// Builds the plain-text export. Its inputs (profile name, sorted notes)
/// are fed in by `ExportPage` from the profile and notes features.
class ExportCubit extends Cubit<ExportState> {
  ExportCubit({required String name, required List<Note> notes})
    : super(ExportState(name: name, notes: notes));

  void nameChanged(String name) => emit(state.copyWith(name: name));

  void notesChanged(List<Note> notes) => emit(state.copyWith(notes: notes));
}
