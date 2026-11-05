import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/notes/notes.dart';
import 'package:notes_app/features/settings/settings.dart';

void main() => runApp(
  App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
);

/// Root widget: provides the storages (repositories) and app-wide blocs.
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: notesStorage),
        RepositoryProvider.value(value: settingsStorage),
      ],
      // Settings are app-wide: both the notes and the settings screen use them.
      child: BlocProvider(
        create: (context) =>
            SettingsCubit(settingsStorage: context.read<SettingsStorage>())
              ..load(),
        child: MaterialApp(
          title: 'Notes',
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          home: const NotesPage(),
        ),
      ),
    );
  }
}
