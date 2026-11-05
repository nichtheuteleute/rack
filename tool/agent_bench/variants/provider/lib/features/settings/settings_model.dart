import 'package:flutter/foundation.dart';

import '../../data/settings_storage.dart';

/// User settings, loaded from and saved to [SettingsStorage].
class SettingsModel extends ChangeNotifier {
  SettingsModel(this._storage);

  final SettingsStorage _storage;

  bool _isLoaded = false;
  bool _newestFirst = false;

  /// Whether [load] has completed.
  bool get isLoaded => _isLoaded;

  /// Show the newest notes first.
  bool get newestFirst => _newestFirst;

  Future<void> load() async {
    _newestFirst = await _storage.loadNewestFirst();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setNewestFirst(bool value) async {
    if (value == _newestFirst) return;
    _newestFirst = value;
    notifyListeners();
    await _storage.saveNewestFirst(value);
  }
}
