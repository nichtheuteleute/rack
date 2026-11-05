import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/settings/settings_model.dart';
import 'package:notes_app/features/settings/settings_screen.dart';
import 'package:notes_app/keys.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('SettingsScreen switch toggles the model', (tester) async {
    final model = SettingsModel(SettingsStorage());
    await tester.runAsync(model.load);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.newestFirst));
    await tester.pump();

    expect(model.newestFirst, isTrue);
    expect(
      tester.widget<SwitchListTile>(find.byKey(AppKeys.newestFirst)).value,
      isTrue,
    );
  });
}
