import 'package:rack/rack.dart';

import '../../data/notes_storage.dart';
import '../settings/settings_module.dart';
import 'notes_store.dart';

/// Provides the [NotesStore]. Depends on [SettingsModule] for the sort order
/// and loads the stored notes in [init].
class NotesModule extends RackModule {
  NotesModule(this.settings, {required NotesStorage storage})
      : _storage = storage,
        super(dependsOn: [settings]);

  final SettingsModule settings;
  final NotesStorage _storage;

  late final notes = use(NotesStore(_storage, settings: settings.settings));

  @override
  Future<void> init() => notes.load();
}
