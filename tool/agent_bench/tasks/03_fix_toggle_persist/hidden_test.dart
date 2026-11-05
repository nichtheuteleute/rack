// HIDDEN TEST — copied in after the agent finished.
import 'package:flutter/material.dart';
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

void main() {
  testWidgets('a toggled note stays toggled after a restart', (tester) async {
    final notes = NotesStorage();
    await _start(tester, notes);

    await tester.tap(find.byKey(AppKeys.toggle('n1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.toggle('n2')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await _start(tester, notes);
    expect(tester.widget<Checkbox>(find.byKey(AppKeys.toggle('n1'))).value,
        isTrue);
    expect(tester.widget<Checkbox>(find.byKey(AppKeys.toggle('n2'))).value,
        isFalse);
    expect(tester.widget<Text>(find.byKey(AppKeys.openCount)).data, '2 open');
  });
}
