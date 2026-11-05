import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/activity_storage.dart';
import 'data/archive_storage.dart';
import 'data/notes_storage.dart';
import 'data/profile_storage.dart';
import 'data/settings_storage.dart';
import 'features/activity/activity_providers.dart';
import 'features/archive/archive_providers.dart';
import 'features/notes/notes_providers.dart';
import 'features/notes/notes_screen.dart';
import 'features/profile/profile_providers.dart';
import 'features/settings/settings_providers.dart';
import 'keys.dart';

void main() => runApp(
  App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
);

/// Root widget: injects the storages into Riverpod and shows the notes screen
/// once the startup data is loaded.
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
  // Fallbacks for storages not passed in; created lazily, once per state.
  late final _profileStorage = ProfileStorage();
  late final _activityStorage = ActivityStorage();
  late final _archiveStorage = ArchiveStorage();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        notesStorageProvider.overrideWithValue(widget.notesStorage),
        settingsStorageProvider.overrideWithValue(widget.settingsStorage),
        profileStorageProvider.overrideWithValue(
          widget.profileStorage ?? _profileStorage,
        ),
        activityStorageProvider.overrideWithValue(
          widget.activityStorage ?? _activityStorage,
        ),
        archiveStorageProvider.overrideWithValue(
          widget.archiveStorage ?? _archiveStorage,
        ),
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
    final startup = [
      ref.watch(notesProvider),
      ref.watch(newestFirstProvider),
      ref.watch(profileNameProvider),
      ref.watch(activityLogProvider),
      ref.watch(archiveProvider),
    ];

    if (startup.map((s) => s.error).nonNulls.firstOrNull case final error?) {
      return Scaffold(body: Center(child: Text('Could not load: $error')));
    }
    if (!startup.every((s) => s.hasValue)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(key: AppKeys.loading)),
      );
    }
    return child;
  }
}
