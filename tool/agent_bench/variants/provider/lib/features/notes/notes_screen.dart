import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../keys.dart';
import '../settings/settings_screen.dart';
import 'notes_model.dart';
import 'widgets/add_note_bar.dart';
import 'widgets/note_tile.dart';
import 'widgets/notes_filter_bar.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          const Center(child: _OpenCount()),
          IconButton(
            key: AppKeys.settings,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: const Column(
        children: [
          AddNoteBar(),
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
    final openCount = context.select((NotesModel m) => m.openCount);
    return Text('$openCount open', key: AppKeys.openCount);
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList();

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesModel>().visibleNotes;
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) => NoteTile(note: notes[index]),
    );
  }
}
