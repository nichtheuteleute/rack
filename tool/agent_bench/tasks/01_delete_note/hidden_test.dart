// HIDDEN TEST — copied in after the agent finished.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/main.dart';

Future<void> _start(WidgetTester tester, NotesStorage notes) async {
  await tester.pumpWidget(
    App(notesStorage: notes, settingsStorage: SettingsStorage()),
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

String _openCount(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(AppKeys.openCount)).data!;

void main() {
  testWidgets('deletes an open note, updates the count and persists',
      (tester) async {
    final notes = NotesStorage();
    await _start(tester, notes);

    await tester.tap(find.byKey(AppKeys.delete('n1')));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.tile('n1')), findsNothing);
    expect(find.text('Buy milk'), findsNothing);
    expect(_openCount(tester), '1 open');

    await tester.pumpWidget(const SizedBox());
    await _start(tester, notes);
    expect(find.text('Buy milk'), findsNothing);
    expect(find.byKey(AppKeys.tile('n3')), findsOneWidget);
  });

  testWidgets('deletes a done note while filtering by done', (tester) async {
    final notes = NotesStorage();
    await _start(tester, notes);

    await tester.tap(find.byKey(AppKeys.filter('done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.delete('n2')));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.tile('n2')), findsNothing);
    expect(_openCount(tester), '2 open');
    final saved = await tester.runAsync(notes.load);
    expect(saved!.map((n) => n.id), ['n1', 'n3']);
  });
}
