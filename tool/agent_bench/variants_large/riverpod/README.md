# notes_app — Riverpod variant

Small notes app (add, toggle, filter, sort, archive, activity log, profile, export, search)
built with
[Riverpod](https://riverpod.dev) 3 and code generation.

```sh
fvm flutter pub get
fvm dart run build_runner build   # or `watch`; regenerates *.g.dart
fvm flutter analyze && fvm flutter test
```

## Architecture

```
lib/
  main.dart            App: ProviderScope with storage overrides (optional ones default to
                       fresh instances held in _AppState), AppStartup loading gate
  keys*.dart, data/    shared widget keys, Note, *Storage classes (do not edit)
  features/<f>/        <f>_providers.dart (+ generated .g.dart), <f>_screen.dart, widgets/
    notes/             Notes, ActiveFilter, sortedNotes, visibleNotes, openCount; drawer
    settings/ profile/ NewestFirst; ProfileName
    activity/          ActivityLog (oldest first), recentActivity (newest first)
    archive/           Archive (archive/restore move notes between both lists)
    export/ search/    exportText; SearchQuery, searchResults (derived only)
test/                  acceptance*_test.dart (shared), features/<f>/, helpers/container.dart
```

- **State** = providers declared with `@riverpod` (auto-dispose; derived/UI state) or
  `@Riverpod(keepAlive: true)` (storages, loaded data). The `.g.dart` parts are generated:
  never edit, re-run `fvm dart run build_runner build` after changing annotated code.
- **Storages** are injected: `<x>StorageProvider` throws unless overridden; `App` overrides
  each with `overrideWithValue` in the root `ProviderScope`.
- **Loading:** storage-backed notifiers are `AsyncNotifier`s. `AppStartup` shows
  `AppKeys.loading` until all of them have a value, so code below it uses `.requireValue`.
- **Business logic** lives in providers: mutations are notifier methods that set `state`, then
  save; filtering/sorting/formatting are derived functional providers; validation helpers
  (`canAddNote`, `canSaveProfileName`) sit next to them. Widgets only `ref.watch(p)` and call
  `ref.read(p.notifier).method()`; text-field drafts stay in widget state.
- **Feature dependencies** are direct: derived providers `ref.watch` other features' providers
  (visibleNotes/export/search -> `sortedNotes` -> `newestFirst`; export -> `profileName`);
  notifiers call other notifiers via `ref.read(p.notifier)` (Notes -> `ActivityLog.record`,
  Archive -> `Notes.remove/insert`). Navigation: `NotesDrawer` pushes the feature screens.
- **Add a feature:** `features/<name>/<name>_providers.dart` (+ `part`) and a screen; run
  build_runner; new data source -> throwing provider overridden in `App`; must load before
  the UI -> watch it in `AppStartup` and `test/helpers/container.dart`. Test notifiers with
  `createLoadedContainer()` (`ProviderContainer.test`), widgets with `UncontrolledProviderScope`.
