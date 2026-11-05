import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/notes/bloc/notes_bloc.dart';
import 'package:notes_app/features/notes/widgets/widgets.dart';
import 'package:notes_app/features/settings/settings.dart';
import 'package:notes_app/keys.dart';

/// Home screen. Reads the app-wide [NotesBloc] provided by `App`.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          const _OpenCount(),
          IconButton(
            key: AppKeys.settings,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(SettingsPage.route()),
          ),
        ],
      ),
      drawer: const NotesDrawer(),
      body: const Column(
        children: [
          NoteInput(),
          NotesFilterBar(),
          Expanded(child: _NotesList()),
        ],
      ),
    );
  }
}

class _OpenCount extends StatelessWidget {
  const _OpenCount();

  @override
  Widget build(BuildContext context) {
    final openCount = context.select((NotesBloc bloc) => bloc.state.openCount);
    return Center(child: Text('$openCount open', key: AppKeys.openCount));
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesBloc, NotesState>(
      // Typing in the input changes only `draft`; don't rebuild the list then.
      buildWhen: (previous, current) =>
          previous.notes != current.notes ||
          previous.filter != current.filter ||
          previous.newestFirst != current.newestFirst,
      builder: (context, state) {
        final notes = state.visibleNotes;
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final bloc = context.read<NotesBloc>();
            return NoteTile(
              key: AppKeys.tile(note.id),
              note: note,
              onToggled: () => bloc.add(NotesNoteToggled(note.id)),
              onArchived: () => bloc.add(NotesNoteArchived(note.id)),
            );
          },
        );
      },
    );
  }
}
