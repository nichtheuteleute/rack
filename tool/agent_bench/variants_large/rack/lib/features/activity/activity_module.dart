import 'package:rack/rack.dart';

import '../../data/activity_storage.dart';
import '../notes/notes_module.dart';
import 'activity_store.dart';

/// Provides the [ActivityStore]. Depends on [NotesModule] for the note events
/// it records and loads the stored log in [init].
class ActivityModule extends RackModule {
  ActivityModule(this.notes, {required ActivityStorage storage})
      : _storage = storage,
        super(dependsOn: [notes]);

  final NotesModule notes;
  final ActivityStorage _storage;

  late final activity =
      use(ActivityStore(_storage, noteEvents: notes.notes.events));

  @override
  Future<void> init() => activity.load();
}
