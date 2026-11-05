// SHARED ACCEPTANCE TEST — every variant must pass it unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/main.dart';

Future<void> startApp(
  WidgetTester tester, {
  NotesStorage? notes,
  SettingsStorage? settings,
}) async {
  await tester.pumpWidget(
    App(
      notesStorage: notes ?? NotesStorage(),
      settingsStorage: settings ?? SettingsStorage(),
    ),
  );
}

Future<void> finishLoading(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

/// Remounts the app with the same storages, to check persistence.
Future<void> restartApp(
  WidgetTester tester,
  NotesStorage notes,
  SettingsStorage settings,
) async {
  await tester.pumpWidget(const SizedBox());
  await startApp(tester, notes: notes, settings: settings);
  await finishLoading(tester);
}

String openCountText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(AppKeys.openCount)).data!;

List<String> visibleNoteIds(WidgetTester tester) {
  final ids = <String>[];
  for (final element in find
      .byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('notes.tile.'))
      .evaluate()) {
    final key = element.widget.key! as ValueKey<String>;
    ids.add(key.value.substring('notes.tile.'.length));
  }
  return ids;
}

void main() {
  testWidgets('shows loading, then the seed notes in creation order',
      (tester) async {
    await startApp(tester);
    expect(find.byKey(AppKeys.loading), findsOneWidget);

    await finishLoading(tester);
    expect(find.byKey(AppKeys.loading), findsNothing);
    expect(visibleNoteIds(tester), ['n1', 'n2', 'n3']);
    expect(find.text('Buy milk'), findsOneWidget);
    expect(openCountText(tester), '2 open');
  });

  testWidgets('add button is disabled for empty or blank input',
      (tester) async {
    await startApp(tester);
    await finishLoading(tester);

    bool addEnabled() {
      final w = tester.widget(find.byKey(AppKeys.add));
      if (w is ButtonStyleButton) return w.onPressed != null;
      if (w is IconButton) return w.onPressed != null;
      if (w is FloatingActionButton) return w.onPressed != null;
      fail('AppKeys.add must be on a button widget, got ${w.runtimeType}');
    }

    expect(addEnabled(), isFalse);
    await tester.enterText(find.byKey(AppKeys.input), '   ');
    await tester.pump();
    expect(addEnabled(), isFalse);
    await tester.enterText(find.byKey(AppKeys.input), 'Hi');
    await tester.pump();
    expect(addEnabled(), isTrue);
  });

  testWidgets('adds a note, clears the input and persists it',
      (tester) async {
    final notes = NotesStorage();
    final settings = SettingsStorage();
    await startApp(tester, notes: notes, settings: settings);
    await finishLoading(tester);

    await tester.enterText(find.byKey(AppKeys.input), 'Water plants');
    await tester.pump();
    await tester.tap(find.byKey(AppKeys.add));
    await tester.pumpAndSettle();

    expect(find.text('Water plants'), findsOneWidget);
    expect(openCountText(tester), '3 open');
    final field = tester.widget<TextField>(find.byKey(AppKeys.input));
    expect(field.controller!.text, isEmpty);

    await restartApp(tester, notes, settings);
    expect(find.text('Water plants'), findsOneWidget);
    expect(visibleNoteIds(tester).last, isNot('n3'));
  });

  testWidgets('toggles a note and persists it', (tester) async {
    final notes = NotesStorage();
    final settings = SettingsStorage();
    await startApp(tester, notes: notes, settings: settings);
    await finishLoading(tester);

    await tester.tap(find.byKey(AppKeys.toggle('n1')));
    await tester.pumpAndSettle();
    expect(openCountText(tester), '1 open');
    expect(tester.widget<Checkbox>(find.byKey(AppKeys.toggle('n1'))).value,
        isTrue);

    await restartApp(tester, notes, settings);
    expect(openCountText(tester), '1 open');
  });

  testWidgets('filters all / open / done', (tester) async {
    await startApp(tester);
    await finishLoading(tester);

    await tester.tap(find.byKey(AppKeys.filter('open')));
    await tester.pumpAndSettle();
    expect(visibleNoteIds(tester), ['n1', 'n3']);

    await tester.tap(find.byKey(AppKeys.filter('done')));
    await tester.pumpAndSettle();
    expect(visibleNoteIds(tester), ['n2']);

    await tester.tap(find.byKey(AppKeys.filter('all')));
    await tester.pumpAndSettle();
    expect(visibleNoteIds(tester), ['n1', 'n2', 'n3']);
  });

  testWidgets('a note toggled while filtering by open disappears',
      (tester) async {
    await startApp(tester);
    await finishLoading(tester);

    await tester.tap(find.byKey(AppKeys.filter('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.toggle('n1')));
    await tester.pumpAndSettle();
    expect(visibleNoteIds(tester), ['n3']);
  });

  testWidgets('newest-first setting reorders the list and persists',
      (tester) async {
    final notes = NotesStorage();
    final settings = SettingsStorage();
    await startApp(tester, notes: notes, settings: settings);
    await finishLoading(tester);

    await tester.tap(find.byKey(AppKeys.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.newestFirst));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(visibleNoteIds(tester), ['n3', 'n2', 'n1']);

    await restartApp(tester, notes, settings);
    expect(visibleNoteIds(tester), ['n3', 'n2', 'n1']);
  });

  testWidgets('starts with newest first when the stored setting says so',
      (tester) async {
    await startApp(tester, settings: SettingsStorage(initialNewestFirst: true));
    await finishLoading(tester);
    expect(visibleNoteIds(tester), ['n3', 'n2', 'n1']);
  });

  testWidgets('a note added with newest first appears at the top',
      (tester) async {
    await startApp(tester, settings: SettingsStorage(initialNewestFirst: true));
    await finishLoading(tester);

    await tester.enterText(find.byKey(AppKeys.input), 'Latest');
    await tester.pump();
    await tester.tap(find.byKey(AppKeys.add));
    await tester.pumpAndSettle();

    final first = visibleNoteIds(tester).first;
    expect(tester.widget<Text>(
      find.descendant(
        of: find.byKey(AppKeys.tile(first)),
        matching: find.text('Latest'),
      ),
    ), isNotNull);
  });
}
