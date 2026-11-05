import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/features/search/search.dart';

void main() {
  final milk = Note(id: 'a', text: 'Buy milk', createdAt: DateTime(2026));
  final bread = Note(id: 'b', text: 'buy BREAD', createdAt: DateTime(2026));
  final mom = Note(id: 'c', text: 'Call mom', createdAt: DateTime(2026));

  group('SearchState.results', () {
    final state = SearchState(notes: [bread, milk, mom]);

    test('are empty for a blank query', () {
      expect(state.results, isEmpty);
      expect(state.copyWith(query: '   ').results, isEmpty);
    });

    test('match the trimmed query ignoring case, in note order', () {
      expect(state.copyWith(query: ' BUY ').results, [bread, milk]);
    });
  });

  blocTest<SearchCubit, SearchState>(
    'follows query and notes changes',
    build: () => SearchCubit(notes: [milk]),
    act: (cubit) => cubit
      ..queryChanged('mom')
      ..notesChanged([milk, mom]),
    expect: () => [
      SearchState(query: 'mom', notes: [milk]),
      SearchState(query: 'mom', notes: [milk, mom]),
    ],
  );
}
