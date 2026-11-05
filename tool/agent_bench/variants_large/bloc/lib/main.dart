import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/activity/activity.dart';
import 'package:notes_app/features/archive/archive.dart';
import 'package:notes_app/features/notes/notes.dart';
import 'package:notes_app/features/profile/profile.dart';
import 'package:notes_app/features/settings/settings.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/repositories/notes_repository.dart';

void main() => runApp(
  App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
);

/// Root widget: provides the repositories and the app-wide blocs.
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
  // Optional storages: created once per App state, not on every build.
  late final _profileStorage = widget.profileStorage ?? ProfileStorage();
  late final _activityStorage = widget.activityStorage ?? ActivityStorage();
  late final _archiveStorage = widget.archiveStorage ?? ArchiveStorage();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.settingsStorage),
        RepositoryProvider.value(value: _profileStorage),
        RepositoryProvider.value(value: _activityStorage),
        // Notes + archive are observed by several blocs, so they get a
        // reactive repository instead of being used directly.
        RepositoryProvider(
          create: (_) => NotesRepository(
            notesStorage: widget.notesStorage,
            archiveStorage: _archiveStorage,
          )..load(),
          dispose: (repository) => repository.dispose(),
        ),
      ],
      // App-wide blocs: used by several routes and loaded at startup.
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                SettingsCubit(settingsStorage: context.read())..load(),
          ),
          BlocProvider(
            create: (context) =>
                ProfileCubit(profileStorage: context.read())..load(),
          ),
          BlocProvider(
            create: (context) => NotesBloc(
              notesRepository: context.read(),
              newestFirst: context.read<SettingsCubit>().state.newestFirst,
            )..add(const NotesStarted()),
          ),
          BlocProvider(
            create: (context) =>
                ArchiveBloc(notesRepository: context.read())
                  ..add(const ArchiveStarted()),
          ),
          BlocProvider(
            create: (context) => ActivityBloc(
              activityStorage: context.read(),
              notesRepository: context.read(),
            )..add(const ActivityStarted()),
          ),
        ],
        child: BlocListener<SettingsCubit, SettingsState>(
          // The notes feature depends on the sort-order setting.
          listenWhen: (previous, current) =>
              previous.newestFirst != current.newestFirst,
          listener: (context, state) => context.read<NotesBloc>().add(
            NotesNewestFirstChanged(state.newestFirst),
          ),
          child: MaterialApp(
            title: 'Notes',
            theme: ThemeData(colorSchemeSeed: Colors.indigo),
            home: const _StartupGate(),
          ),
        ),
      ),
    );
  }
}

/// Shows [AppKeys.loading] until every app-wide bloc has loaded its data.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final loaded = [
      context.select(
        (SettingsCubit c) => c.state.status == SettingsStatus.success,
      ),
      context.select(
        (ProfileCubit c) => c.state.status == ProfileStatus.success,
      ),
      context.select((NotesBloc b) => b.state.status == NotesStatus.success),
      context.select(
        (ArchiveBloc b) => b.state.status == ArchiveStatus.success,
      ),
      context.select(
        (ActivityBloc b) => b.state.status == ActivityStatus.success,
      ),
    ].every((isLoaded) => isLoaded);

    if (!loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(key: AppKeys.loading)),
      );
    }
    return const NotesPage();
  }
}
