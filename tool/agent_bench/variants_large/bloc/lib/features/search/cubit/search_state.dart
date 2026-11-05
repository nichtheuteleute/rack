part of 'search_cubit.dart';

final class SearchState extends Equatable {
  const SearchState({this.query = '', required this.notes});

  final String query;

  /// Notes in the current sort order (not archived).
  final List<Note> notes;

  /// Notes whose text contains the trimmed [query], ignoring case; none for
  /// an empty query.
  List<Note> get results {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return [
      for (final note in notes)
        if (note.text.toLowerCase().contains(needle)) note,
    ];
  }

  SearchState copyWith({String? query, List<Note>? notes}) {
    return SearchState(query: query ?? this.query, notes: notes ?? this.notes);
  }

  @override
  List<Object> get props => [query, notes];
}
