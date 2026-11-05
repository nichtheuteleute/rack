// HIDDEN TEST — copied in after the agent finished.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/main.dart';

Future<void> _start(WidgetTester tester) async {
  await tester.pumpWidget(
    App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()),
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

Future<void> _open(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows totals and order for the seed data', (tester) async {
    await _start(tester);
    await _open(tester, AppKeys.stats);

    expect(find.text('Statistics'), findsOneWidget);
    expect(_text(tester, AppKeys.statsTotal), '3 total');
    expect(_text(tester, AppKeys.statsDone), '1 done');
    expect(_text(tester, AppKeys.statsOrder), 'Oldest first');
  });

  testWidgets('reflects changes to notes and settings', (tester) async {
    await _start(tester);

    await tester.tap(find.byKey(AppKeys.toggle('n1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AppKeys.input), 'Another');
    await tester.pump();
    await tester.tap(find.byKey(AppKeys.add));
    await tester.pumpAndSettle();

    await _open(tester, AppKeys.settings);
    await tester.tap(find.byKey(AppKeys.newestFirst));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _open(tester, AppKeys.stats);
    expect(_text(tester, AppKeys.statsTotal), '4 total');
    expect(_text(tester, AppKeys.statsDone), '2 done');
    expect(_text(tester, AppKeys.statsOrder), 'Newest first');
  });
}
