import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/activity/activity_providers.dart';
import 'package:notes_app/features/archive/archive_providers.dart';
import 'package:notes_app/features/notes/notes_providers.dart';
import 'package:notes_app/features/profile/profile_providers.dart';
import 'package:notes_app/features/settings/settings_providers.dart';

/// Notes with creation order b, c, a; b is done.
final testNotes = [
  Note(id: 'a', text: 'A', createdAt: DateTime(2026, 3, 1)),
  Note(id: 'b', text: 'B', createdAt: DateTime(2026, 1, 1), done: true),
  Note(id: 'c', text: 'C', createdAt: DateTime(2026, 2, 1)),
];

/// A container with every storage overridden and all startup state loaded,
/// as `AppStartup` guarantees in the app. Disposed after the test.
Future<ProviderContainer> createLoadedContainer({
  NotesStorage? notes,
  SettingsStorage? settings,
  ProfileStorage? profile,
  ActivityStorage? activity,
  ArchiveStorage? archive,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      notesStorageProvider.overrideWithValue(
        notes ?? NotesStorage(initial: testNotes),
      ),
      settingsStorageProvider.overrideWithValue(settings ?? SettingsStorage()),
      profileStorageProvider.overrideWithValue(profile ?? ProfileStorage()),
      activityStorageProvider.overrideWithValue(activity ?? ActivityStorage()),
      archiveStorageProvider.overrideWithValue(archive ?? ArchiveStorage()),
    ],
  );
  await Future.wait([
    container.read(notesProvider.future),
    container.read(newestFirstProvider.future),
    container.read(profileNameProvider.future),
    container.read(activityLogProvider.future),
    container.read(archiveProvider.future),
  ]);
  return container;
}

List<String> ids(List<Note> notes) => [for (final n in notes) n.id];

/// Keeps an auto-dispose provider alive for the test and returns a reader.
T Function() watch<T>(ProviderContainer container, ProviderListenable<T> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
  return sub.read;
}
