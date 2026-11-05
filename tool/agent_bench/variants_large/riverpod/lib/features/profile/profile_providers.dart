import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/profile_storage.dart';

part 'profile_providers.g.dart';

/// The profile persistence. `App` overrides it in the root `ProviderScope`.
@Riverpod(keepAlive: true)
ProfileStorage profileStorage(Ref ref) =>
    throw UnimplementedError('profileStorageProvider must be overridden');

/// Whether [name] is acceptable as the profile name.
bool canSaveProfileName(String name) => name.trim().isNotEmpty;

/// The user's name. Loaded from and saved to [ProfileStorage].
@Riverpod(keepAlive: true)
class ProfileName extends _$ProfileName {
  @override
  Future<String> build() => ref.watch(profileStorageProvider).loadName();

  /// Saves the trimmed [name]. Ignores blank names.
  Future<void> save(String name) {
    if (!canSaveProfileName(name)) return Future.value();
    final trimmed = name.trim();
    state = AsyncData(trimmed);
    return ref.read(profileStorageProvider).saveName(trimmed);
  }
}
