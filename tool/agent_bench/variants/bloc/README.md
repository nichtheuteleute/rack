# notes_app (Bloc variant)

A small notes app built with [`flutter_bloc`](https://bloclibrary.dev): add notes, tick them off, filter by all/open/done, and sort newest first (a setting).

```sh
fvm flutter test      # acceptance test + bloc tests
fvm flutter analyze
```

## Architecture

```
lib/
  main.dart                  App: RepositoryProvider(storages) + BlocProvider(SettingsCubit) + MaterialApp
  keys.dart, data/           shared (do not change): AppKeys, Note, NotesStorage, SettingsStorage
  features/<feature>/
    <feature>.dart           barrel file; other code imports only this
    bloc/ or cubit/          <X>Bloc/<X>Cubit + part files <x>_event.dart / <x>_state.dart
    models/                  feature types (e.g. NotesFilter)
    view/<x>_page.dart       Page = providers/listeners, View = UI
    widgets/                 feature widgets (+ widgets.dart barrel)
test/                        mirrors lib/; acceptance_test.dart is shared and must stay unchanged
```

**State.** The storages are the repositories: `App` provides them with `RepositoryProvider.value`, and blocs get them through the constructor (`context.read<NotesStorage>()` inside `BlocProvider.create`). `settings` is a `SettingsCubit` (one value, so a Cubit is enough) provided above `MaterialApp` because two routes use it. `notes` is a `NotesBloc` (several user events) provided by `NotesPage`. Each state is one Equatable class with a `status` enum and `copyWith`. Derived values (`visibleNotes`, `openCount`, `canAdd`) are getters on the state, never computed in widgets. Events are a `sealed` class named `<Subject><Noun?><PastVerb>` (e.g. `NotesNoteToggled`). Handlers `emit` the new state first, then persist (`NotesStorage.save` with the whole list).

**Reading state.** Widgets use `context.select((NotesBloc b) => b.state.x)` for single values, `BlocBuilder` with `buildWhen` for lists, and send input with `context.read<NotesBloc>().add(...)` or call cubit methods. Widgets hold no business logic. `NoteInput` keeps a `TextEditingController` only so it can clear the field. The draft text lives in the bloc.

**Feature dependencies.** Blocs never reference other blocs. `notes` depends on `settings` through the presentation layer: `NotesPage` gives `NotesBloc` its starting `newestFirst` from `SettingsCubit`, and a `BlocListener<SettingsCubit, SettingsState>` forwards later changes as `NotesNewestFirstChanged`. `NotesView` shows `AppKeys.loading` until both blocs reach `status == success`.

**Adding a feature `foo`.**
1. If it needs a new data source, add it in `data/` and provide it in `App`'s `MultiRepositoryProvider`.
2. Create `features/foo/` with `cubit/` (simple state) or `bloc/` (several events, or event transformers needed), `view/foo_page.dart`, and the `foo.dart` barrel.
3. Provide the bloc in `FooPage` if only that route uses it. Otherwise provide it in `App` above `MaterialApp`.
4. If it reacts to another feature, add a `BlocListener` in the page that forwards an event. Don't inject one bloc into another.
5. Add keys to `AppKeys` (never rename existing ones), and add `blocTest`s in `test/features/foo/`.
