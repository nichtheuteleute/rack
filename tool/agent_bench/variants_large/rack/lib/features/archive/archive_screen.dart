import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys_large.dart';
import 'archive_controller.dart';
import 'archive_module.dart';

class ArchiveScreen extends RackWidget<ArchiveController> {
  const ArchiveScreen({super.key});

  @override
  ArchiveController create(Rack rack) =>
      ArchiveController(archiveStore: rack.module<ArchiveModule>().archive);

  @override
  Widget buildContent(BuildContext context, ArchiveController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: SignalBuilder(
        builder: (context) {
          final notes = controller.archived.value;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                key: LargeKeys.archiveTile(note.id),
                title: Text(note.text),
                trailing: IconButton(
                  key: LargeKeys.restore(note.id),
                  tooltip: 'Restore',
                  icon: const Icon(Icons.unarchive_outlined),
                  onPressed: () => controller.restore(note),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
