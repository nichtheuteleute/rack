import 'package:signals_flutter/signals_flutter.dart';

import 'settings_store.dart';

/// Controller of the settings screen.
class SettingsController {
  SettingsController({required SettingsStore settingsStore})
      : _settings = settingsStore;

  final SettingsStore _settings;

  ReadonlySignal<bool> get newestFirst => _settings.newestFirst;

  Future<void> setNewestFirst(bool value) => _settings.setNewestFirst(value);
}
