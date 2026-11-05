import 'package:signals_flutter/signals_flutter.dart';

import '../../data/note.dart';
import 'archive_store.dart';

/// Controller of the archive screen.
class ArchiveController {
  ArchiveController({required ArchiveStore archiveStore})
      : _archive = archiveStore;

  final ArchiveStore _archive;

  ReadonlySignal<List<Note>> get archived => _archive.archived;

  Future<void> restore(Note note) => _archive.restore(note);
}
