# notes_app — Riverpod variant

Small notes app (add, toggle, filter, sort newest first) built with
[Riverpod](https://riverpod.dev) 3 and code generation.

```sh
fvm flutter pub get
fvm dart run build_runner build   # or `watch`; regenerates *.g.dart
fvm flutter analyze && fvm flutter test
```

## Architecture

```
lib/
  main.dart                 App: ProviderScope with storage overrides, AppStartup gate
  keys.dart, data/          shared widget keys, Note, NotesStorage, SettingsStorage (do not edit)
  features/settings/        settings_providers.dart (settingsStorage, NewestFirst), settings_screen.dart
  features/notes/           notes_providers.dart (notesStorage, Notes, ActiveFilter, visibleNotes,
                            openCount, canAddNote), notes_screen.dart, widgets/
test/                       acceptance_test.dart (shared) + features/<feature>/ tests
```

- **State** lives in providers declared with `@riverpod` / `@Riverpod(keepAlive: true)` in
  `features/<f>/<f>_providers.dart`; `part '<f>_providers.g.dart'` is generated — never edit it,
  re-run build_runner after changing an annotated declaration.
- **Storages** are injected: `notesStorageProvider` / `settingsStorageProvider` throw unless
  overridden; `App` overrides them with `overrideWithValue` in the root `ProviderScope`.
- **Async loading:** `Notes` and `NewestFirst` are `AsyncNotifier`s loading from storage.
  `AppStartup` (main.dart) shows `AppKeys.loading` until both have a value; everything below
  it (screens, derived providers) may therefore use `.requireValue`.
- **Business logic** stays in providers: mutations are notifier methods that set `state`
  and then persist (`Notes.add/toggle`, `NewestFirst.change`); filtering, sorting and counting
  are derived functional providers (`visibleNotes`, `openCount`); validation is `canAddNote`.
- **Widgets** are `ConsumerWidget`s: `ref.watch(xProvider)` to render,
  `ref.read(xProvider.notifier).method()` in callbacks. Ephemeral UI state (the text field's
  controller) stays in the widget.
- **Feature dependencies** are plain `ref.watch` across features: `visibleNotes` watches
  `newestFirstProvider` from settings; the notes screen pushes `SettingsScreen`. Settings
  does not depend on notes.
- **Add a feature:** create `features/<name>/` with `<name>_providers.dart` (+ `part`), a
  screen and `widgets/`; run build_runner; if it needs a new data source, add a throwing
  provider and override it in `App`; if it must be loaded before the UI shows, watch it in
  `AppStartup`. Test notifiers with `ProviderContainer.test(overrides: …)`, widgets with
  `ProviderScope`/`UncontrolledProviderScope`.
