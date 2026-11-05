// SHARED ACCEPTANCE TEST for the extension features — must pass unchanged.
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

class Storages {
  final notes = NotesStorage();
  SettingsStorage settings = SettingsStorage();
  ProfileStorage profile = ProfileStorage();
  final activity = ActivityStorage();
  final archive = ArchiveStorage();
}

Future<void> start(WidgetTester tester, Storages s) async {
  await tester.pumpWidget(App(
    notesStorage: s.notes,
    settingsStorage: s.settings,
    profileStorage: s.profile,
    activityStorage: s.activity,
    archiveStorage: s.archive,
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> restart(WidgetTester tester, Storages s) async {
  await tester.pumpWidget(const SizedBox());
  await start(tester, s);
}

Future<void> openScreen(WidgetTester tester, Key navKey) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(navKey));
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

String text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

List<String> idsWithPrefix(String prefix) => [
      for (final e in find
          .byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(prefix))
          .evaluate())
        (e.widget.key! as ValueKey<String>).value.substring(prefix.length),
    ];

Future<void> addNote(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(AppKeys.input), value);
  await tester.pump();
  await tester.tap(find.byKey(AppKeys.add));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('works with only the original storages', (tester) async {
    await tester.pumpWidget(
      App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
  });

  testWidgets('profile: shows, validates and saves the name', (tester) async {
    final s = Storages();
    await start(tester, s);
    await openScreen(tester, LargeKeys.navProfile);
    expect(find.text('Profile'), findsWidgets);

    final field = tester.widget<TextField>(find.byKey(LargeKeys.profileName));
    expect(field.controller!.text, 'Alex');

    await tester.enterText(find.byKey(LargeKeys.profileName), '  ');
    await tester.pump();
    final button =
        tester.widget<ButtonStyleButton>(find.byKey(LargeKeys.profileSave));
    expect(button.onPressed, isNull);

    await tester.enterText(find.byKey(LargeKeys.profileName), ' Sam ');
    await tester.pump();
    await tester.tap(find.byKey(LargeKeys.profileSave));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(s.profile.loadName), 'Sam');
  });

  testWidgets('activity: records adds and completions, newest first',
      (tester) async {
    final s = Storages();
    await start(tester, s);
    await addNote(tester, 'Read book');
    await tester.tap(find.byKey(AppKeys.toggle('n1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.toggle('n1'))); // back to open
    await tester.pumpAndSettle();

    await openScreen(tester, LargeKeys.navActivity);
    expect(text(tester, LargeKeys.activityEntry(0)), 'Completed: Buy milk');
    expect(text(tester, LargeKeys.activityEntry(1)), 'Added: Read book');
    expect(find.byKey(LargeKeys.activityEntry(2)), findsNothing);

    await back(tester);
    await restart(tester, s);
    await openScreen(tester, LargeKeys.navActivity);
    expect(text(tester, LargeKeys.activityEntry(0)), 'Completed: Buy milk');
  });

  testWidgets('archive: archive and restore a note, persisted',
      (tester) async {
    final s = Storages();
    await start(tester, s);

    await tester.tap(find.byKey(LargeKeys.archive('n1')));
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.tile('n1')), findsNothing);
    expect(text(tester, AppKeys.openCount), '1 open');

    await restart(tester, s);
    expect(find.byKey(AppKeys.tile('n1')), findsNothing);
    await openScreen(tester, LargeKeys.navArchive);
    expect(find.byKey(LargeKeys.archiveTile('n1')), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);

    await tester.tap(find.byKey(LargeKeys.restore('n1')));
    await tester.pumpAndSettle();
    expect(find.byKey(LargeKeys.archiveTile('n1')), findsNothing);
    await back(tester);
    expect(idsWithPrefix('notes.tile.'), ['n1', 'n2', 'n3']);
    expect(text(tester, AppKeys.openCount), '2 open');
  });

  testWidgets('export: reflects profile, notes, archive and sort order',
      (tester) async {
    final s = Storages();
    await start(tester, s);
    await openScreen(tester, LargeKeys.navExport);
    expect(
      text(tester, LargeKeys.exportText),
      'Notes of Alex\n- [ ] Buy milk\n- [x] Write report\n- [ ] Call mom',
    );
    await back(tester);

    await tester.tap(find.byKey(LargeKeys.archive('n2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.newestFirst));
    await tester.pumpAndSettle();
    await back(tester);
    await openScreen(tester, LargeKeys.navProfile);
    await tester.enterText(find.byKey(LargeKeys.profileName), 'Sam');
    await tester.pump();
    await tester.tap(find.byKey(LargeKeys.profileSave));
    await tester.pumpAndSettle();
    await back(tester);

    await openScreen(tester, LargeKeys.navExport);
    expect(
      text(tester, LargeKeys.exportText),
      'Notes of Sam\n- [ ] Call mom\n- [ ] Buy milk',
    );
  });

  testWidgets('search: case-insensitive, sorted, excludes archived',
      (tester) async {
    final s = Storages()..settings = SettingsStorage(initialNewestFirst: true);
    await start(tester, s);
    await addNote(tester, 'Buy bread');
    await tester.tap(find.byKey(LargeKeys.archive('n3')));
    await tester.pumpAndSettle();

    await openScreen(tester, LargeKeys.navSearch);
    expect(idsWithPrefix('search.result.'), isEmpty);
    await tester.enterText(find.byKey(LargeKeys.searchInput), ' BUY ');
    await tester.pumpAndSettle();
    final ids = idsWithPrefix('search.result.');
    expect(ids, hasLength(2));
    expect(ids.last, 'n1');
    await tester.enterText(find.byKey(LargeKeys.searchInput), 'mom');
    await tester.pumpAndSettle();
    expect(idsWithPrefix('search.result.'), isEmpty);
  });
}
