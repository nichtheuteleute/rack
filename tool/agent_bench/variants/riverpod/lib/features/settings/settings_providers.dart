import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings_storage.dart';

part 'settings_providers.g.dart';

/// The settings persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.
@Riverpod(keepAlive: true)
SettingsStorage settingsStorage(Ref ref) =>
    throw UnimplementedError('settingsStorageProvider must be overridden');

/// Whether notes are listed newest first. Loaded from and saved to
/// [SettingsStorage].
@Riverpod(keepAlive: true)
class NewestFirst extends _$NewestFirst {
  @override
  Future<bool> build() => ref.watch(settingsStorageProvider).loadNewestFirst();

  Future<void> change(bool value) {
    state = AsyncData(value);
    return ref.read(settingsStorageProvider).saveNewestFirst(value);
  }
}
