import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/notes/notes.dart';
import 'package:notes_app/features/search/cubit/search_cubit.dart';
import 'package:notes_app/keys_large.dart';

/// Provides the [SearchCubit] and keeps it in sync with the sorted notes
/// (which already reflect the sort-order setting).
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const SearchPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SearchCubit(notes: context.read<NotesBloc>().state.sortedNotes),
      child: BlocListener<NotesBloc, NotesState>(
        listenWhen: (previous, current) =>
            previous.notes != current.notes ||
            previous.newestFirst != current.newestFirst,
        listener: (context, state) =>
            context.read<SearchCubit>().notesChanged(state.sortedNotes),
        child: const SearchView(),
      ),
    );
  }
}

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: LargeKeys.searchInput,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search notes',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: context.read<SearchCubit>().queryChanged,
            ),
          ),
          const Expanded(child: _SearchResults()),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final results = state.results;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final note = results[index];
            return ListTile(
              key: LargeKeys.searchResult(note.id),
              title: Text(note.text),
            );
          },
        );
      },
    );
  }
}
