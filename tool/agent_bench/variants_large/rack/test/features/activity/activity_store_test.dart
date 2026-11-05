import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/activity/activity_store.dart';
import 'package:notes_app/features/notes/notes_store.dart';
import 'package:notes_app/features/settings/settings_store.dart';

void main() {
  late ActivityStorage storage;
  late NotesStore notes;
  late ActivityStore activity;

  setUp(() async {
    storage = ActivityStorage(initial: ['Added: Old']);
    notes = NotesStore(
      NotesStorage(initial: [
        Note(id: 'a', text: 'Old', createdAt: DateTime(2026, 1, 1)),
      ]),
      settings: SettingsStore(SettingsStorage()),
    );
    await notes.load();
    activity = ActivityStore(storage, noteEvents: notes.events);
    await activity.load();
  });

  tearDown(() {
    activity.dispose();
    notes.dispose();
  });

  test('records adds and completions newest first, and saves them', () async {
    await notes.add('New');
    await notes.toggle('a');
    await pumpEventQueue();

    expect(
        activity.entries.value, ['Completed: Old', 'Added: New', 'Added: Old']);
    expect(
        await storage.load(), ['Added: Old', 'Added: New', 'Completed: Old']);
  });

  test('records nothing when a note is reopened', () async {
    await notes.toggle('a');
    await notes.toggle('a');
    await pumpEventQueue();

    expect(activity.entries.value, ['Completed: Old', 'Added: Old']);
  });
}
