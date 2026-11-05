import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../keys.dart';
import '../settings/settings_screen.dart';
import 'notes_providers.dart';
import 'widgets/add_note_bar.dart';
import 'widgets/filter_bar.dart';
import 'widgets/notes_drawer.dart';
import 'widgets/note_tile.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(visibleNotesProvider);
    final openCount = ref.watch(openCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          Center(child: Text('$openCount open', key: AppKeys.openCount)),
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
      drawer: const NotesDrawer(),
      body: Column(
        children: [
          const AddNoteBar(),
          const FilterBar(),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) => NoteTile(note: notes[index]),
            ),
          ),
        ],
      ),
    );
  }
}
