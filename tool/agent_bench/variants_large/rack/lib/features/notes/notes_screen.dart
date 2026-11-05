import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys.dart';
import '../archive/archive_module.dart';
import '../settings/settings_screen.dart';
import 'notes_controller.dart';
import 'notes_module.dart';
import 'widgets/note_input.dart';
import 'widgets/note_tile.dart';
import 'widgets/notes_drawer.dart';
import 'widgets/notes_filter_bar.dart';

class NotesScreen extends RackWidget<NotesController> {
  const NotesScreen({super.key});

  @override
  NotesController create(Rack rack) => NotesController(
        notesStore: rack.module<NotesModule>().notes,
        archiveStore: rack.module<ArchiveModule>().archive,
      );

  @override
  Widget buildContent(BuildContext context, NotesController controller) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          Center(
            child: SignalBuilder(
              builder: (context) => Text(
                '${controller.openCount.value} open',
                key: AppKeys.openCount,
              ),
            ),
          ),
          IconButton(
            key: AppKeys.settings,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: const NotesDrawer(),
      body: Column(
        children: [
          NoteInput(controller: controller),
          NotesFilterBar(controller: controller),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final notes = controller.visibleNotes.value;
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) =>
                      NoteTile(note: notes[index], controller: controller),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
