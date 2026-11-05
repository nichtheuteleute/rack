import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/notes_storage.dart';
import 'data/settings_storage.dart';
import 'features/notes/notes_providers.dart';
import 'features/notes/notes_screen.dart';
import 'features/settings/settings_providers.dart';
import 'keys.dart';

void main() => runApp(
  App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
);

/// Root widget: injects the storages into Riverpod and shows the notes screen
/// once the startup data is loaded.
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
    return ProviderScope(
      overrides: [
        notesStorageProvider.overrideWithValue(notesStorage),
        settingsStorageProvider.overrideWithValue(settingsStorage),
      ],
      child: const MaterialApp(
        title: 'Notes',
        home: AppStartup(child: NotesScreen()),
      ),
    );
  }
}

/// Shows a loading indicator until the async state every screen relies on is
/// loaded, so screens and derived providers can use `requireValue`.
class AppStartup extends ConsumerWidget {
  const AppStartup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final newestFirst = ref.watch(newestFirstProvider);

    if (notes.error ?? newestFirst.error case final error?) {
      return Scaffold(body: Center(child: Text('Could not load: $error')));
    }
    if (!notes.hasValue || !newestFirst.hasValue) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(key: AppKeys.loading)),
      );
    }
    return child;
  }
}
