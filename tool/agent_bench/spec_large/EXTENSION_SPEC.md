# Extension spec: five more features

Extends the existing "Notes" app (see `APP_SPEC.md` rules — they all still apply: idiomatic for your library, logic in the state layer, organised by feature, `fvm flutter analyze` clean, all tests green, shared files unchanged).

## Shared files

Copy unchanged into the project:
- `shared/lib/data/profile_storage.dart`, `activity_storage.dart`, `archive_storage.dart` → `lib/data/`
- `shared/lib/keys_large.dart` → `lib/keys_large.dart`
- `acceptance/acceptance_large_test.dart` → `test/acceptance_large_test.dart`

The existing `test/acceptance_test.dart` must keep passing unchanged.

## App

`App` gets three more **optional** named parameters: `ProfileStorage? profileStorage`, `ActivityStorage? activityStorage`, `ArchiveStorage? archiveStorage`. If one is null, the app uses a fresh instance, created once per `App` state (not on every build). The loading widget (`AppKeys.loading`) stays visible until the profile name, the activity log and the archive are loaded as well.

The notes screen gets a `Drawer` (opened from the app bar's standard menu button) with five `ListTile`s, keys `LargeKeys.navProfile`, `navActivity`, `navArchive`, `navExport`, `navSearch`. Tapping one closes the drawer and pushes that feature's screen. Each screen has an app bar with the title given below.

## Features

1. **Profile** — screen "Profile". A `TextField` (`LargeKeys.profileName`) prefilled with the stored name and a button (`LargeKeys.profileSave`, a Material button) that saves the trimmed text with `ProfileStorage.saveName`. The button is disabled while the trimmed text is empty.

2. **Activity log** — screen "Activity". The notes feature records entries:
   - adding a note → `"Added: <text>"`
   - toggling a note from open to done → `"Completed: <text>"` (toggling back records nothing)

   Entries are persisted with `ActivityStorage.save` (whole list, oldest first). The screen lists them **newest first** as `Text` widgets with keys `LargeKeys.activityEntry(0)` (newest), `activityEntry(1)`, …

3. **Archive** — every note tile gets an icon button (`LargeKeys.archive(id)`). Archiving removes the note from the notes list (saved with `NotesStorage.save`) and appends it to the archive (saved with `ArchiveStorage.save`). Archived notes do not count as open. Screen "Archive" lists archived notes (tile key `LargeKeys.archiveTile(id)`, showing the text) with a restore icon button (`LargeKeys.restore(id)`) that removes the note from the archive and puts it back into the notes list unchanged (same id, text, done, createdAt), both saved.

4. **Export** — screen "Export" shows one `Text` (`LargeKeys.exportText`) with:
   ```
   Notes of <profile name>
   - [ ] <text of an open note>
   - [x] <text of a done note>
   ```
   One line per note in the notes list (not archived), in the current sort order (ignoring the filter), lines joined with `\n`. It always reflects the current profile name, notes and sort order.

5. **Search** — screen "Search". A `TextField` (`LargeKeys.searchInput`); below it one tile per note in the notes list whose text contains the trimmed query, case-insensitive (key `LargeKeys.searchResult(id)`, showing the text), in the current sort order. An empty query shows no results.

Wire dependencies between features the way your library intends (activity depends on notes events, export on profile + notes + settings, search on notes + settings, archive on notes).

## Tests and docs

Add focused tests for each new feature the way your project already does. Update the README's Architecture section (still at most 40 lines).
