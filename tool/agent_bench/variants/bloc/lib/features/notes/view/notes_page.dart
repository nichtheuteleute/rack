import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/notes/bloc/notes_bloc.dart';
import 'package:notes_app/features/notes/widgets/widgets.dart';
import 'package:notes_app/features/settings/settings.dart';
import 'package:notes_app/keys.dart';

/// Provides the [NotesBloc] and feeds it the sort order from [SettingsCubit].
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotesBloc(
        notesStorage: context.read<NotesStorage>(),
        newestFirst: context.read<SettingsCubit>().state.newestFirst,
      )..add(const NotesStarted()),
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            previous.newestFirst != current.newestFirst,
        listener: (context, state) => context.read<NotesBloc>().add(
          NotesNewestFirstChanged(state.newestFirst),
        ),
        child: const NotesView(),
      ),
    );
  }
}

class NotesView extends StatelessWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final notesLoaded = context.select(
      (NotesBloc bloc) => bloc.state.status == NotesStatus.success,
    );
    final settingsLoaded = context.select(
      (SettingsCubit cubit) => cubit.state.status == SettingsStatus.success,
    );

    if (!notesLoaded || !settingsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(key: AppKeys.loading)),
      );
    }

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
            return NoteTile(
              key: AppKeys.tile(note.id),
              note: note,
              onToggled: () =>
                  context.read<NotesBloc>().add(NotesNoteToggled(note.id)),
            );
          },
        );
      },
    );
  }
}
