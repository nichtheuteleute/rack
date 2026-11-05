The activity log should also record archiving.

- Archiving a note records `"Archived: <text>"`.
- Restoring a note from the archive records `"Restored: <text>"`.

Like the existing entries, they are persisted and shown newest first on the activity screen.

Follow the existing architecture and conventions of this project, and add tests the way the project does. When you are done, `fvm flutter analyze` must report no issues and `fvm flutter test` must pass.
