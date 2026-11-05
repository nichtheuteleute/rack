# notes_app (provider)

A small notes app built with [provider](https://pub.dev/packages/provider)
(`ChangeNotifier` + `ChangeNotifierProvider` / `ChangeNotifierProxyProvider`).

```sh
fvm flutter test      # acceptance test + per-feature tests
fvm flutter analyze
```

## Architecture

```
lib/
  main.dart                 App: MultiProvider wiring, MaterialApp, startup spinner (_Home)
  keys.dart, data/          shared, do not edit (storages + Note)
  features/settings/        settings_model.dart (SettingsModel) + settings_screen.dart
  features/notes/           notes_model.dart (NotesModel, NotesFilter) + notes_screen.dart
    widgets/                add_note_bar, notes_filter_bar, note_tile
test/features/<feature>/    unit tests of the models, widget tests of screens
```

**State.** One `ChangeNotifier` per feature (`XxxModel`) holds all state and business
logic: loading, filtering, sorting, counting, validation (`canAdd`) and persistence.
Mutating methods update fields, call `notifyListeners()`, then save to the storage.
Widgets only render and forward actions; ephemeral UI state (the `TextEditingController`)
stays in a `StatefulWidget`.

**Providing.** `App` (main.dart) builds one `MultiProvider` above `MaterialApp`, so all
routes see it. Storages are passed into `App` and exposed with `Provider.value`; models
get them in `create` via `context.read<XxxStorage>()` and start `..load()` there.
Models are disposed by their provider.

**Reading.** In `build`: `context.select((XxxModel m) => m.field)` for one value,
`context.watch<XxxModel>()` for many. In callbacks: `context.read<XxxModel>().action()`.
Never `watch`/`select` outside `build`.

**Dependencies between features.** Notes need the sort order from settings. Wired with
`ChangeNotifierProxyProvider<SettingsModel, NotesModel>`: `update` runs whenever
`SettingsModel` notifies and pushes the value into the existing model
(`notes!..newestFirst = settings.newestFirst`); the setter notifies only on change.
Models never import or read each other directly; the dependent provider must be listed
after the one it depends on.

**Adding a feature.** Create `lib/features/<name>/` with `<name>_model.dart` (a
`ChangeNotifier` taking its storage/dependencies via the constructor) and
`<name>_screen.dart`. Register it in `App`'s `MultiProvider` (`ChangeNotifierProvider`,
or `ChangeNotifierProxyProvider` if it depends on another model). Add
`test/features/<name>/` with plain unit tests of the model (construct it with a storage,
call methods, assert fields / `addListener` counts) and, for screens, widget tests using
`ChangeNotifierProvider.value`. New test keys go into `keys.dart` (add, never rename).
