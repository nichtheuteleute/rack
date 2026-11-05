// SHARED FILE — identical in every variant. Do not change.

/// Pretend persistence for user settings. [load] takes 50 ms.
class SettingsStorage {
  SettingsStorage({bool initialNewestFirst = false})
      : _newestFirst = initialNewestFirst;

  bool _newestFirst;

  Future<bool> loadNewestFirst() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _newestFirst;
  }

  Future<void> saveNewestFirst(bool value) async => _newestFirst = value;
}
