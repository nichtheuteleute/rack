import 'package:rack/rack.dart';

import '../../data/archive_storage.dart';
import '../notes/notes_module.dart';
import 'archive_store.dart';

/// Provides the [ArchiveStore]. Depends on [NotesModule], whose list it moves
/// notes out of and back into, and loads the stored archive in [init].
class ArchiveModule extends RackModule {
  ArchiveModule(this.notes, {required ArchiveStorage storage})
      : _storage = storage,
        super(dependsOn: [notes]);

  final NotesModule notes;
  final ArchiveStorage _storage;

  late final archive = use(ArchiveStore(_storage, notes: notes.notes));

  @override
  Future<void> init() => archive.load();
}
