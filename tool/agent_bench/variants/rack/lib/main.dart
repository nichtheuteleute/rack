import 'package:flutter/material.dart';
import 'package:rack/rack.dart';

import 'data/notes_storage.dart';
import 'data/settings_storage.dart';
import 'features/notes/notes_module.dart';
import 'features/notes/notes_screen.dart';
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
  });

  final NotesStorage notesStorage;
  final SettingsStorage settingsStorage;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _settings = SettingsModule(storage: widget.settingsStorage);
  late final _notes = NotesModule(_settings, storage: widget.notesStorage);

  @override
  Widget build(BuildContext context) {
    return RackProvider(
      modules: [_settings, _notes],
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
