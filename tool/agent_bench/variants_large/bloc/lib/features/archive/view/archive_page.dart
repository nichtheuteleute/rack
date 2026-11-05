import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/archive/bloc/archive_bloc.dart';
import 'package:notes_app/keys_large.dart';

/// Archive screen. Reads the app-wide [ArchiveBloc].
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const ArchivePage());
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.select((ArchiveBloc bloc) => bloc.state.notes);
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
              tooltip: 'Restore',
              icon: const Icon(Icons.unarchive_outlined),
              onPressed: () =>
                  context.read<ArchiveBloc>().add(ArchiveNoteRestored(note.id)),
            ),
          );
        },
      ),
    );
  }
}
