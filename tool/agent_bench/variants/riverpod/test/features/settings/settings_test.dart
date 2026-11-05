import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/settings/settings_providers.dart';
import 'package:notes_app/features/settings/settings_screen.dart';
import 'package:notes_app/keys.dart';

void main() {
  test('newestFirst loads from and saves to the storage', () async {
    final storage = SettingsStorage(initialNewestFirst: true);
    final container = ProviderContainer.test(
      overrides: [settingsStorageProvider.overrideWithValue(storage)],
    );

    expect(await container.read(newestFirstProvider.future), isTrue);

    await container.read(newestFirstProvider.notifier).change(false);

    expect(container.read(newestFirstProvider).requireValue, isFalse);
    expect(await storage.loadNewestFirst(), isFalse);
  });

  testWidgets('settings screen switch toggles newestFirst', (tester) async {
    final storage = SettingsStorage();
    final container = ProviderContainer.test(
      overrides: [settingsStorageProvider.overrideWithValue(storage)],
    );
    // The screen expects loaded settings, as `AppStartup` guarantees.
    await tester.runAsync(() => container.read(newestFirstProvider.future));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.tap(find.byKey(AppKeys.newestFirst));
    await tester.pump();

    expect(
      tester.widget<SwitchListTile>(find.byKey(AppKeys.newestFirst)).value,
      isTrue,
    );
    expect(container.read(newestFirstProvider).requireValue, isTrue);
    expect(await tester.runAsync(storage.loadNewestFirst), isTrue);
  });
}
