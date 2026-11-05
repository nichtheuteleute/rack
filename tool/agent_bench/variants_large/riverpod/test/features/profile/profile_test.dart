import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/features/profile/profile_providers.dart';
import 'package:notes_app/features/profile/profile_screen.dart';
import 'package:notes_app/keys_large.dart';

void main() {
  test('profileName loads, saves trimmed and ignores blank names', () async {
    final storage = ProfileStorage(initialName: 'Kim');
    final container = ProviderContainer.test(
      overrides: [profileStorageProvider.overrideWithValue(storage)],
    );
    expect(await container.read(profileNameProvider.future), 'Kim');

    await container.read(profileNameProvider.notifier).save('  Sam ');
    expect(container.read(profileNameProvider).requireValue, 'Sam');
    expect(await storage.loadName(), 'Sam');

    await container.read(profileNameProvider.notifier).save('   ');
    expect(container.read(profileNameProvider).requireValue, 'Sam');
    expect(canSaveProfileName(' '), isFalse);
  });

  testWidgets('profile screen prefills the name and saves edits', (
    tester,
  ) async {
    final storage = ProfileStorage(initialName: 'Kim');
    final container = ProviderContainer.test(
      overrides: [profileStorageProvider.overrideWithValue(storage)],
    );
    await tester.runAsync(() => container.read(profileNameProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    expect(find.text('Kim'), findsOneWidget);

    await tester.enterText(find.byKey(LargeKeys.profileName), 'Lee ');
    await tester.pump();
    await tester.tap(find.byKey(LargeKeys.profileSave));
    await tester.pump();

    expect(container.read(profileNameProvider).requireValue, 'Lee');
    expect(await tester.runAsync(storage.loadName), 'Lee');
  });
}
