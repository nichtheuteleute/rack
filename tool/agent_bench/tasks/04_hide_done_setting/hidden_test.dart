// HIDDEN TEST — copied in after the agent finished.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/main.dart';

Future<void> _start(
  WidgetTester tester,
  NotesStorage notes,
  SettingsStorage settings,
) async {
  await tester.pumpWidget(App(notesStorage: notes, settingsStorage: settings));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

List<String> _ids(WidgetTester tester) => [
      for (final e in find
          .byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('notes.tile.'))
          .evaluate())
        (e.widget.key! as ValueKey<String>).value.substring('notes.tile.'.length),
    ];

void main() {
  testWidgets('hides done notes in every filter and persists', (tester) async {
    final notes = NotesStorage();
    final settings = SettingsStorage();
    await _start(tester, notes, settings);

    await tester.tap(find.byKey(AppKeys.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.hideDone));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(_ids(tester), ['n1', 'n3']);
    expect(tester.widget<Text>(find.byKey(AppKeys.openCount)).data, '2 open');
    await tester.tap(find.byKey(AppKeys.filter('done')));
    await tester.pumpAndSettle();
    expect(_ids(tester), isEmpty);

    await tester.pumpWidget(const SizedBox());
    await _start(tester, notes, settings);
    expect(_ids(tester), ['n1', 'n3']);
  });

  testWidgets('starts hidden when stored, and a newly done note disappears',
      (tester) async {
    await _start(
      tester,
      NotesStorage(),
      SettingsStorage(initialHideDone: true),
    );
    expect(_ids(tester), ['n1', 'n3']);

    await tester.tap(find.byKey(AppKeys.toggle('n1')));
    await tester.pumpAndSettle();
    expect(_ids(tester), ['n3']);
    expect(tester.widget<Text>(find.byKey(AppKeys.openCount)).data, '1 open');
  });

  testWidgets('switch is off by default and shows the label', (tester) async {
    await _start(tester, NotesStorage(), SettingsStorage());
    await tester.tap(find.byKey(AppKeys.settings));
    await tester.pumpAndSettle();
    expect(find.text('Hide done notes'), findsOneWidget);
  });
}
