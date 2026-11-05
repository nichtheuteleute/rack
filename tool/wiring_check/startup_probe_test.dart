// Copied into every mutated copy: starts the app and prints what it shows,
// so errors an app catches and renders (instead of throwing) are visible.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/main.dart';

void main() {
  testWidgets('startup probe', (tester) async {
    await tester.pumpWidget(
        App(notesStorage: NotesStorage(), settingsStorage: SettingsStorage()));
    await tester.pump(const Duration(milliseconds: 200));
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      debugPrint('PROBE TEXT: ${t.data}');
    }
  });
}
