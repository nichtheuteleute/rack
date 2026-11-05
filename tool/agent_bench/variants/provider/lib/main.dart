import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/notes_storage.dart';
import 'data/settings_storage.dart';
import 'features/notes/notes_model.dart';
import 'features/notes/notes_screen.dart';
import 'features/settings/settings_model.dart';
import 'keys.dart';

void main() => runApp(
  App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
);

/// Root widget: provides the storages and the feature models, then the UI.
class App extends StatelessWidget {
  const App({
    super.key,
    required this.notesStorage,
    required this.settingsStorage,
  });

  final NotesStorage notesStorage;
  final SettingsStorage settingsStorage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Existing instances: `.value`, so provider does not own them.
        Provider.value(value: notesStorage),
        Provider.value(value: settingsStorage),
        ChangeNotifierProvider(
          create: (context) =>
              SettingsModel(context.read<SettingsStorage>())..load(),
        ),
        // Notes depend on settings (sort order): `update` runs on every
        // SettingsModel change and pushes the new value into NotesModel.
        ChangeNotifierProxyProvider<SettingsModel, NotesModel>(
          create: (context) => NotesModel(context.read<NotesStorage>())..load(),
          update: (context, settings, notes) =>
              notes!..newestFirst = settings.newestFirst,
        ),
      ],
      child: MaterialApp(
        title: 'Notes',
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const _Home(),
      ),
    );
  }
}

/// Shows a spinner until settings and notes are loaded.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    // Both selects run unconditionally, so both models are created (and
    // start loading) on the first frame.
    final settingsLoaded = context.select((SettingsModel s) => s.isLoaded);
    final notesLoaded = context.select((NotesModel n) => n.isLoaded);
    if (!settingsLoaded || !notesLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(key: AppKeys.loading)),
      );
    }
    return const NotesScreen();
  }
}
