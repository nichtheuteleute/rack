import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/notes/bloc/notes_bloc.dart';
import 'package:notes_app/features/notes/models/notes_filter.dart';
import 'package:notes_app/keys.dart';

class NotesFilterBar extends StatelessWidget {
  const NotesFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.select((NotesBloc bloc) => bloc.state.filter);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<NotesFilter>(
        segments: [
          for (final value in NotesFilter.values)
            ButtonSegment(
              value: value,
              label: Text(_label(value), key: AppKeys.filter(value.name)),
            ),
        ],
        selected: {filter},
        onSelectionChanged: (selection) =>
            context.read<NotesBloc>().add(NotesFilterChanged(selection.single)),
      ),
    );
  }

  static String _label(NotesFilter filter) => switch (filter) {
    NotesFilter.all => 'All',
    NotesFilter.open => 'Open',
    NotesFilter.done => 'Done',
  };
}
