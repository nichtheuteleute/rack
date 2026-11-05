import 'package:flutter/material.dart';
import 'package:rack/rack.dart';

import 'data/activity_storage.dart';
import 'data/archive_storage.dart';
import 'data/notes_storage.dart';
import 'data/profile_storage.dart';
import 'data/settings_storage.dart';
import 'features/activity/activity_module.dart';
import 'features/archive/archive_module.dart';
import 'features/notes/notes_module.dart';
import 'features/notes/notes_screen.dart';
import 'features/profile/profile_module.dart';
import 'features/settings/settings_module.dart';
import 'keys.dart';

void main() => runApp(
      App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
    );

/// Composition root: creates the modules from the injected storages and
/// provides them to the whole app.
class App extends StatefulWidget {
  const App({
    super.key,
    required this.notesStorage,
    required this.settingsStorage,
    this.profileStorage,
    this.activityStorage,
    this.archiveStorage,
  });

  final NotesStorage notesStorage;
  final SettingsStorage settingsStorage;
  final ProfileStorage? profileStorage;
  final ActivityStorage? activityStorage;
  final ArchiveStorage? archiveStorage;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _settings = SettingsModule(storage: widget.settingsStorage);
  late final _profile =
      ProfileModule(storage: widget.profileStorage ?? ProfileStorage());
  late final _notes = NotesModule(_settings, storage: widget.notesStorage);
  late final _activity = ActivityModule(
    _notes,
    storage: widget.activityStorage ?? ActivityStorage(),
  );
  late final _archive = ArchiveModule(
    _notes,
    storage: widget.archiveStorage ?? ArchiveStorage(),
  );

  @override
  Widget build(BuildContext context) {
    return RackProvider(
      // Dependencies first: notes needs settings; activity and archive need notes.
      modules: [_settings, _profile, _notes, _activity, _archive],
      loading: const Center(
        child: CircularProgressIndicator(key: AppKeys.loading),
      ),
      builder: () => const MaterialApp(
        title: 'Notes',
        home: NotesScreen(),
      ),
    );
  }
}
