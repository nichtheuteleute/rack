import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../keys_large.dart';
import 'archive_providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(archiveProvider).requireValue;

    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            key: LargeKeys.archiveTile(note.id),
            title: Text(note.text),
            trailing: IconButton(
              key: LargeKeys.restore(note.id),
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: 'Restore',
              onPressed: () =>
                  ref.read(archiveProvider.notifier).restore(note.id),
            ),
          );
        },
      ),
    );
  }
}
