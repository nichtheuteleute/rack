# Benchmark app spec: "Notes"

The same small app is built three times — with **rack + signals**, with **Riverpod** and with **Bloc** — so AI coding agents can be measured on identical tasks in each code base. Each variant must be a code base a senior developer of that library would call idiomatic and well structured. Do not make any variant deliberately worse or better.

## Package

- Flutter package named `notes_app`, Flutter via fvm (`fvm flutter …`, version pinned in `.fvmrc`: `3.47.8`).
- Copy `shared/lib/**` unchanged into `lib/` (`lib/data/note.dart`, `lib/data/notes_storage.dart`, `lib/data/settings_storage.dart`, `lib/keys.dart`).
- Copy `acceptance/acceptance_test.dart` unchanged into `test/`. It must pass.
- `fvm flutter analyze` must report no issues with `flutter_lints` (`analysis_options.yaml`: `include: package:flutter_lints/flutter.yaml`).
- `lib/main.dart` exports:

  ```dart
  class App extends StatelessWidget/StatefulWidget {
    const App({super.key, required this.notesStorage, required this.settingsStorage});
    final NotesStorage notesStorage;
    final SettingsStorage settingsStorage;
  }
  void main() => runApp(App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()));
  ```
  The storages are the app's only data sources and must be injected from here into the state layer the way the library recommends.
- Use only the state library of the variant plus Flutter. No other packages (dev: `flutter_test`, `flutter_lints`, plus code-generation packages if the library's docs recommend them).

## Behaviour

1. **Startup:** load the "newest first" setting and the notes asynchronously. Until both are loaded, show a widget with key `AppKeys.loading` (e.g. a centered `CircularProgressIndicator`).
2. **Notes screen** (home, `MaterialApp` + `Scaffold`):
   - App bar title "Notes", a text with key `AppKeys.openCount` showing `"<n> open"` (number of notes not done), and an icon button with key `AppKeys.settings` that pushes the settings screen.
   - A `TextField` (key `AppKeys.input`) and an add button (key `AppKeys.add`, a Material button). The button is disabled while the trimmed input is empty. Adding creates a note with `id: notesStorage.newId()`, the trimmed text, `createdAt: DateTime.now()`, clears the input and persists.
   - A filter with three segments `all`, `open`, `done` (keys `AppKeys.filter('all')` etc.), default `all`.
   - The list of notes matching the filter. Each note is a tile with key `AppKeys.tile(note.id)` that shows the text and a `Checkbox` (key `AppKeys.toggle(note.id)`) toggling `done`. Toggling persists.
   - Order: by `createdAt` ascending, or descending when "newest first" is on.
   - Every change to the notes is saved with `NotesStorage.save` (the whole list).
3. **Settings screen:** app bar "Settings", a `SwitchListTile` or `Switch` with key `AppKeys.newestFirst` for "Newest first". Changing it is saved with `SettingsStorage.saveNewestFirst` and is reflected on the notes screen immediately.

## Structure

Organise by feature, the way the library's documentation recommends:

```
lib/
  main.dart            App, dependency wiring
  keys.dart            shared
  data/                shared storages + Note
  features/
    settings/          settings state + settings screen
    notes/             notes state + notes screen (+ widgets)
```

The notes feature depends on the settings feature (sort order) — wire that dependency the way the library intends.

Business logic (filtering, sorting, counting, validation, persistence calls) lives in the state layer, not in widgets. Widgets render state and forward user actions.

## Documentation

Write `README.md` for the variant with an **Architecture** section of **at most 40 lines**: folder layout, how state is provided and read, how features depend on each other, how to add a feature. This is the only project documentation an agent will see — make it as useful as you can within the limit.

Also add at least one focused unit or widget test of your own per feature (besides the acceptance test), the way the library's docs recommend testing.
