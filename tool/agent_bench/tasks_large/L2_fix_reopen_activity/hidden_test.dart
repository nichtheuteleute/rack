// HIDDEN TEST — copied in after the agent finished.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/activity_storage.dart';
import 'package:notes_app/data/archive_storage.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/keys_large.dart';
import 'package:notes_app/main.dart';

void main() {
  testWidgets('re-opening a note records nothing, completing still does',
      (tester) async {
    final activity = ActivityStorage();
    await tester.pumpWidget(App(
      notesStorage: NotesStorage(),
      settingsStorage: SettingsStorage(),
      profileStorage: ProfileStorage(),
      activityStorage: activity,
      archiveStorage: ArchiveStorage(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.toggle('n2'))); // done -> open
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.toggle('n1'))); // open -> done
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.toggle('n1'))); // done -> open
    await tester.pumpAndSettle();

    expect(await tester.runAsync(activity.load), ['Completed: Buy milk']);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LargeKeys.navActivity));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(LargeKeys.activityEntry(0))).data,
        'Completed: Buy milk');
    expect(find.byKey(LargeKeys.activityEntry(1)), findsNothing);
  });
}
