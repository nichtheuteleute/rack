import 'package:signals_flutter/signals_flutter.dart';

import '../../data/settings_storage.dart';

/// App-wide user settings, loaded once at startup and saved on every change.
class SettingsStore {
  SettingsStore(this._storage);

  final SettingsStorage _storage;

  final _newestFirst = signal(false);

  /// Whether notes are listed newest first.
  ReadonlySignal<bool> get newestFirst => _newestFirst;

  Future<void> load() async {
    _newestFirst.value = await _storage.loadNewestFirst();
  }

  Future<void> setNewestFirst(bool value) async {
    _newestFirst.value = value;
    await _storage.saveNewestFirst(value);
  }
}
