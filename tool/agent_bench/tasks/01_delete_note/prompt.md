Add the ability to delete notes.

- Every note tile gets a delete icon button. Add a key for it to `lib/keys.dart`:
  `static Key delete(String id) => Key('notes.delete.$id');` and put that key on the button.
- Tapping it removes the note from the list and saves the remaining notes with `NotesStorage.save`. The open counter updates accordingly.

Follow the existing architecture and conventions of this project, and add or update tests the way the project does. When you are done, `fvm flutter analyze` must report no issues and `fvm flutter test` must pass.
