# notes_app (Bloc variant)

A notes app built with [`flutter_bloc`](https://bloclibrary.dev): add, tick off, filter, sort (setting), archive/restore notes, plus profile, activity log, export and search screens (drawer).

```sh
fvm flutter test      # acceptance tests + bloc tests
fvm flutter analyze
```

## Architecture

```
lib/
  main.dart                  App (StatefulWidget): repositories, app-wide blocs, settings→notes listener, startup gate
  keys.dart, keys_large.dart, data/   shared (do not change): keys, Note, *Storage
  repositories/notes_repository.dart  reactive domain layer for notes + archive (streams + NoteChange events)
  features/<feature>/        notes, settings, profile, activity, archive, export, search
    <feature>.dart           barrel file; other code imports only this
    bloc/ or cubit/          <X>Bloc/<X>Cubit + part files <x>_event.dart / <x>_state.dart
    view/<x>_page.dart       <X>Page (+ <X>View if the page provides a page-scoped cubit/listeners)
    widgets/, models/        feature widgets / types (notes: tiles, filter bar, drawer, NotesFilter)
test/                        mirrors lib/ (blocTest); acceptance_*_test.dart are shared, never edit
```

**Data.** Storages are data providers. `App` provides settings/profile/activity storages directly with `RepositoryProvider.value` (one owner each). Notes + archive are read by several blocs, so `App` wraps them in `NotesRepository`: it persists every change, publishes `notes`/`archive` streams (replaying the latest value) and a `changes` stream (`NoteAdded`, `NoteCompleted`). Optional storages are created once in `_AppState`.

**State.** Cubit for simple load/save or input state (`SettingsCubit`, `ProfileCubit`, page-scoped `ProfileFormCubit`, `ExportCubit`, `SearchCubit`). Bloc for anything that subscribes to repository streams (`emit.forEach`/`onEach`) or has many events (`NotesBloc`, `ArchiveBloc`, `ActivityBloc`). Each state is one Equatable class (`status` enum if it loads, `copyWith`). Derived values are state getters (`sortedNotes`, `visibleNotes`, `openCount`, `canAdd`, `results`, `text`, `latestFirst`). Events: sealed, `<Subject><Noun?><PastVerb>`, private for internal ones (`_ActivityNoteChanged`). App-wide blocs live above `MaterialApp`; `_StartupGate` shows `AppKeys.loading` until all of them report success.

**Reading state.** `context.select` for single values, `BlocBuilder` (with `buildWhen`) for lists, `context.read<X>().add(...)`/cubit methods for input. Widgets hold no logic; text controllers exist only to prefill or clear fields (drafts live in blocs).

**Feature dependencies.** A bloc never references another bloc. Two ways to connect them:
- Domain (shared data or events): subscribe to `NotesRepository`. `ArchiveBloc` restores via `restoreNote`; archiving is `NotesNoteArchived` (`NotesBloc`); `ActivityBloc` records `changes`.
- Presentation (derived from another feature's state): seed the bloc in `create` with the current state, then forward changes with `BlocListener`. That's settings→notes in `App`, notes(`sortedNotes`)+profile→export in `ExportPage`, notes→search in `SearchPage`.
The notes screen is the hub: settings button + `NotesDrawer` push the other pages' `route()`.

**Adding a feature `foo`.**
1. New data: a storage in `data/` provided in `App`. If several blocs observe it, add a reactive repository in `repositories/`.
2. Create `features/foo/` with `cubit/` or `bloc/`, `view/foo_page.dart` (`static Route<void> route()`), and the `foo.dart` barrel.
3. Provide the bloc in `FooPage` if only that route uses it. Otherwise provide it in `App`'s `MultiBlocProvider` and add it to `_StartupGate` if it loads at startup.
4. Connect it to other features as above, never bloc→bloc. Add a drawer `ListTile` in `NotesDrawer`.
5. Add keys to `LargeKeys`/`AppKeys` (never rename existing ones), and add `blocTest`s in `test/features/foo/`.
