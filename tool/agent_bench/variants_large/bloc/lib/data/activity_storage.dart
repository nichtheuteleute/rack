// SHARED FILE — identical in every variant. Do not change.

/// Pretend persistence for the activity log. Entries are stored oldest
/// first. [load] takes 50 ms.
class ActivityStorage {
  ActivityStorage({List<String>? initial}) : _entries = List.of(initial ?? []);

  List<String> _entries;

  Future<List<String>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List.of(_entries);
  }

  Future<void> save(List<String> entries) async => _entries = List.of(entries);
}
