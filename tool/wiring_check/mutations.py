"""Every wiring step of each variant: a place a developer has to write so that
a dependency reaches the code that needs it. Each mutation removes exactly one
of them (the smallest edit that "forgets" it).

Lookups that are also the usage (`rack.module<T>()`, `ref.watch(x)`,
`context.read<T>()` in a widget that uses the result) are not wiring steps:
you cannot forget them without also removing the code that needs them.
"""

MUTATIONS = {
    "rack": [
        ("root: settings module not listed in RackProvider",
         "lib/main.dart", "modules: [_settings, _notes],", "modules: [_notes],"),
        ("root: notes module not listed in RackProvider",
         "lib/main.dart", "modules: [_settings, _notes],", "modules: [_settings],"),
        ("notes feature does not get the settings module",
         "lib/main.dart",
         "NotesModule(_settings, storage: widget.notesStorage)",
         "NotesModule(storage: widget.notesStorage)"),
        ("settings module does not get its storage",
         "lib/main.dart",
         "SettingsModule(storage: widget.settingsStorage)",
         "SettingsModule()"),
        ("notes module does not get its storage",
         "lib/main.dart",
         "NotesModule(_settings, storage: widget.notesStorage)",
         "NotesModule(_settings)"),
    ],
    "riverpod": [
        ("root: notes storage not overridden",
         "lib/main.dart",
         "        notesStorageProvider.overrideWithValue(notesStorage),\n", ""),
        ("root: settings storage not overridden",
         "lib/main.dart",
         "        settingsStorageProvider.overrideWithValue(settingsStorage),\n",
         ""),
    ],
    "bloc": [
        ("root: notes storage not provided",
         "lib/main.dart",
         "        RepositoryProvider.value(value: notesStorage),\n", ""),
        ("root: settings storage not provided",
         "lib/main.dart",
         "        RepositoryProvider.value(value: settingsStorage),\n", ""),
        ("root: SettingsCubit not provided",
         "lib/main.dart",
         """      child: BlocProvider(
        create: (context) =>
            SettingsCubit(settingsStorage: context.read<SettingsStorage>())
              ..load(),
        child: MaterialApp(
          title: 'Notes',
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          home: const NotesPage(),
        ),
      ),""",
         """      child: MaterialApp(
        title: 'Notes',
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const NotesPage(),
      ),"""),
        ("settings cubit does not get its storage",
         "lib/main.dart",
         "SettingsCubit(settingsStorage: context.read<SettingsStorage>())",
         "SettingsCubit()"),
        ("NotesBloc not provided on the notes page",
         "lib/features/notes/view/notes_page.dart",
         """    return BlocProvider(
      create: (context) => NotesBloc(
        notesStorage: context.read<NotesStorage>(),
        newestFirst: context.read<SettingsCubit>().state.newestFirst,
      )..add(const NotesStarted()),
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            previous.newestFirst != current.newestFirst,
        listener: (context, state) => context.read<NotesBloc>().add(
          NotesNewestFirstChanged(state.newestFirst),
        ),
        child: const NotesView(),
      ),
    );""",
         """    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.newestFirst != current.newestFirst,
      listener: (context, state) => context.read<NotesBloc>().add(
        NotesNewestFirstChanged(state.newestFirst),
      ),
      child: const NotesView(),
    );"""),
        ("notes bloc does not get its storage",
         "lib/features/notes/view/notes_page.dart",
         "        notesStorage: context.read<NotesStorage>(),\n", ""),
        ("notes feature does not get the initial sort order from settings",
         "lib/features/notes/view/notes_page.dart",
         "        newestFirst: context.read<SettingsCubit>().state.newestFirst,\n",
         ""),
        ("notes feature does not listen to settings changes",
         "lib/features/notes/view/notes_page.dart",
         """      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            previous.newestFirst != current.newestFirst,
        listener: (context, state) => context.read<NotesBloc>().add(
          NotesNewestFirstChanged(state.newestFirst),
        ),
        child: const NotesView(),
      ),""",
         """      child: const NotesView(),"""),
    ],
    "provider": [
        ("root: notes storage not provided",
         "lib/main.dart",
         "        Provider.value(value: notesStorage),\n", ""),
        ("root: settings storage not provided",
         "lib/main.dart",
         "        Provider.value(value: settingsStorage),\n", ""),
        ("root: SettingsModel not provided",
         "lib/main.dart",
         """        ChangeNotifierProvider(
          create: (context) =>
              SettingsModel(context.read<SettingsStorage>())..load(),
        ),
""", ""),
        ("root: NotesModel not provided",
         "lib/main.dart",
         """        ChangeNotifierProxyProvider<SettingsModel, NotesModel>(
          create: (context) => NotesModel(context.read<NotesStorage>())..load(),
          update: (context, settings, notes) =>
              notes!..newestFirst = settings.newestFirst,
        ),
""", ""),
        ("settings model does not get its storage",
         "lib/main.dart",
         "SettingsModel(context.read<SettingsStorage>())", "SettingsModel()"),
        ("notes model does not get its storage",
         "lib/main.dart",
         "NotesModel(context.read<NotesStorage>())", "NotesModel()"),
        ("notes feature does not get the settings",
         "lib/main.dart",
         """          update: (context, settings, notes) =>
              notes!..newestFirst = settings.newestFirst,""",
         """          update: (context, settings, notes) => notes!,"""),
    ],
}

# Additional scenario: the rack variant with dependencies declared in
# `dependsOn`, as the rack README recommends. Same mutations as "rack".
VARIANT_SOURCE = {"rack_dependsOn": "rack"}
PREPARE = {
    "rack_dependsOn": [
        ("lib/features/settings/settings_module.dart",
         "  late final settings = use(SettingsStore(_storage));\n",
         "  late final settings = use(SettingsStore(_storage));\n\n"
         "  @override\n  List<RackModule> get dependsOn => const [];\n"),
        ("lib/features/notes/notes_module.dart",
         "  @override\n  Future<void> init() => notes.load();\n",
         "  @override\n  List<RackModule> get dependsOn => [settings];\n\n"
         "  @override\n  Future<void> init() => notes.load();\n"),
    ],
}
MUTATIONS["rack_dependsOn"] = MUTATIONS["rack"]

