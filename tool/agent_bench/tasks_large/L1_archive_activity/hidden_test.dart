// HIDDEN TEST — copied in after the agent finished.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/keys_large.dart';
import 'package:notes_app/main.dart';

Future<void> _start(WidgetTester tester, NotesStorage notes,
    ActivityStorage activity, ArchiveStorage archive) async {
  await tester.pumpWidget(App(
    notesStorage: notes,
    settingsStorage: SettingsStorage(),
    profileStorage: ProfileStorage(),
    activityStorage: activity,
    archiveStorage: archive,
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, Key key) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

String _entry(WidgetTester tester, int i) =>
    tester.widget<Text>(find.byKey(LargeKeys.activityEntry(i))).data!;

void main() {
  testWidgets('archiving and restoring are logged and persisted',
      (tester) async {
    final notes = NotesStorage();
    final activity = ActivityStorage(initial: ['Added: Old']);
    final archive = ArchiveStorage();
    await _start(tester, notes, activity, archive);

    await tester.tap(find.byKey(LargeKeys.archive('n1')));
    await tester.pumpAndSettle();
    await _open(tester, LargeKeys.navArchive);
    await tester.tap(find.byKey(LargeKeys.restore('n1')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _open(tester, LargeKeys.navActivity);
    expect(_entry(tester, 0), 'Restored: Buy milk');
    expect(_entry(tester, 1), 'Archived: Buy milk');
    expect(_entry(tester, 2), 'Added: Old');

    await tester.pumpWidget(const SizedBox());
    await _start(tester, notes, activity, archive);
    await _open(tester, LargeKeys.navActivity);
    expect(_entry(tester, 0), 'Restored: Buy milk');
    expect(_entry(tester, 1), 'Archived: Buy milk');
  });
}
