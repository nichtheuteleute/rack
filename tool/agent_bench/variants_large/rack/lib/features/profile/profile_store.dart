import 'package:signals_flutter/signals_flutter.dart';

import '../../data/profile_storage.dart';

/// The user's profile, loaded once at startup and saved on every change.
class ProfileStore {
  ProfileStore(this._storage);

  final ProfileStorage _storage;

  final _name = signal('');

  /// The saved profile name.
  ReadonlySignal<String> get name => _name;

  Future<void> load() async {
    _name.value = await _storage.loadName();
  }

  Future<void> saveName(String name) async {
    _name.value = name;
    await _storage.saveName(name);
  }
}
