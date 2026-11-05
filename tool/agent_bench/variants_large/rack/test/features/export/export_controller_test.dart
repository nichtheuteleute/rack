import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/export/export_controller.dart';
import 'package:notes_app/features/notes/notes_store.dart';
import 'package:notes_app/features/profile/profile_store.dart';
import 'package:notes_app/features/settings/settings_store.dart';

void main() {
  late SettingsStore settings;
  late ProfileStore profile;
  late NotesStore notes;
  late ExportController controller;

  setUp(() async {
    settings = SettingsStore(SettingsStorage());
    profile = ProfileStore(ProfileStorage(initialName: 'Alex'));
    notes = NotesStore(
      NotesStorage(initial: [
        Note(id: 'a', text: 'Old', createdAt: DateTime(2026, 1, 1)),
        Note(id: 'b', text: 'New', createdAt: DateTime(2026, 2, 1), done: true),
      ]),
      settings: settings,
    );
    await Future.wait([profile.load(), notes.load()]);
    controller = ExportController(profileStore: profile, notesStore: notes);
  });

  tearDown(() {
    controller.dispose();
    notes.dispose();
  });

  test('renders a checklist headed by the profile name', () {
    expect(controller.text.value, 'Notes of Alex\n- [ ] Old\n- [x] New');
  });

  test('follows name, sort order and note changes', () async {
    await profile.saveName('Sam');
    await settings.setNewestFirst(true);
    await notes.toggle('a');

    expect(controller.text.value, 'Notes of Sam\n- [x] New\n- [x] Old');
  });
}
