import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/settings/settings_model.dart';

void main() {
  group('SettingsModel', () {
    test('loads the stored value and notifies', () async {
      final model = SettingsModel(SettingsStorage(initialNewestFirst: true));
      var notified = 0;
      model.addListener(() => notified++);

      expect(model.isLoaded, isFalse);
      await model.load();

      expect(model.isLoaded, isTrue);
      expect(model.newestFirst, isTrue);
      expect(notified, 1);
    });

    test('setNewestFirst updates, notifies and persists', () async {
      final storage = SettingsStorage();
      final model = SettingsModel(storage);
      await model.load();
      var notified = 0;
      model.addListener(() => notified++);

      await model.setNewestFirst(true);

      expect(model.newestFirst, isTrue);
      expect(notified, 1);
      expect(await storage.loadNewestFirst(), isTrue);
    });

    test('setNewestFirst with the current value does nothing', () async {
      final model = SettingsModel(SettingsStorage());
      await model.load();
      var notified = 0;
      model.addListener(() => notified++);

      await model.setNewestFirst(false);

      expect(notified, 0);
    });
  });
}
