// SHARED FILE — identical in every variant. Do not change.

/// Pretend persistence for the user's profile. [loadName] takes 50 ms.
class ProfileStorage {
  ProfileStorage({String initialName = 'Alex'}) : _name = initialName;

  String _name;

  Future<String> loadName() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _name;
  }

  Future<void> saveName(String name) async => _name = name;
}
