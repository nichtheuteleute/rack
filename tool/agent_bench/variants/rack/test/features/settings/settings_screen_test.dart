import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/settings/settings_module.dart';
import 'package:notes_app/features/settings/settings_screen.dart';
import 'package:notes_app/keys.dart';
import 'package:rack/rack.dart';

void main() {
  /// Mounts the settings screen with its module and waits for `init()`.
  Future<SettingsModule> pumpScreen(
    WidgetTester tester,
    SettingsStorage storage,
  ) async {
    final module = SettingsModule(storage: storage);
    await tester.pumpWidget(RackProvider(
      modules: [module],
      builder: () => const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    return module;
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byKey(AppKeys.newestFirst)).value;

  testWidgets('shows the stored setting', (tester) async {
    await pumpScreen(tester, SettingsStorage(initialNewestFirst: true));

    expect(switchValue(tester), isTrue);
  });

  testWidgets('toggling the switch updates the store and saves',
      (tester) async {
    final storage = SettingsStorage();
    final module = await pumpScreen(tester, storage);

    await tester.tap(find.byKey(AppKeys.newestFirst));
    await tester.pump();

    expect(switchValue(tester), isTrue);
    expect(module.settings.newestFirst.value, isTrue);
    await tester.runAsync(() async {
      expect(await storage.loadNewestFirst(), isTrue);
    });
  });

  testWidgets('rebuilds when the store changes elsewhere', (tester) async {
    final module = await pumpScreen(tester, SettingsStorage());

    await module.settings.setNewestFirst(true);
    await tester.pump();

    expect(switchValue(tester), isTrue);
  });
}
