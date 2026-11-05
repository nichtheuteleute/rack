Add a setting "Hide done notes".

- The settings screen gets a switch labelled "Hide done notes" with the key `static const hideDone = Key('settings.hideDone');` (add it to `lib/keys.dart`). Default: off.
- Persist it like the existing setting: extend `SettingsStorage` with a constructor parameter `bool initialHideDone = false`, `Future<bool> loadHideDone()` (with the same 50 ms delay as the existing load) and `Future<void> saveHideDone(bool value)`. Load it at startup together with the existing setting.
- While it is on, done notes are not shown in the notes list, in any filter (so the "done" filter shows an empty list). The open counter is not affected.

Follow the existing architecture and conventions of this project, and add tests the way the project does. When you are done, `fvm flutter analyze` must report no issues and `fvm flutter test` must pass.
