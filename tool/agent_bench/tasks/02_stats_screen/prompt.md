Add a statistics screen as a new feature.

- The notes screen's app bar gets an icon button that opens it. Add its key to `lib/keys.dart`: `static const stats = Key('nav.stats');`
- The statistics screen has the app bar title "Statistics" and shows three texts. Add their keys to `lib/keys.dart` as well:
  - `static const statsTotal = Key('stats.total');` showing `"<n> total"` (all notes),
  - `static const statsDone = Key('stats.done');` showing `"<n> done"`,
  - `static const statsOrder = Key('stats.order');` showing `"Newest first"` or `"Oldest first"`, depending on the current setting.
- The values always reflect the current notes and settings.

Follow the existing architecture and conventions of this project, and add tests the way the project does. When you are done, `fvm flutter analyze` must report no issues and `fvm flutter test` must pass.
