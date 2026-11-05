import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/note.dart';

part 'search_state.dart';

/// Searches the notes. The sorted notes are fed in by `SearchPage` from the
/// notes feature.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required List<Note> notes}) : super(SearchState(notes: notes));

  void queryChanged(String query) => emit(state.copyWith(query: query));

  void notesChanged(List<Note> notes) => emit(state.copyWith(notes: notes));
}
