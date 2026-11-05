import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/activity_storage.dart';

part 'activity_providers.g.dart';

/// The activity persistence. `App` overrides it in the root `ProviderScope`.
@Riverpod(keepAlive: true)
ActivityStorage activityStorage(Ref ref) =>
    throw UnimplementedError('activityStorageProvider must be overridden');

/// The activity log, oldest first. Other features add entries with [record];
/// every change is saved with [ActivityStorage.save].
@Riverpod(keepAlive: true)
class ActivityLog extends _$ActivityLog {
  @override
  Future<List<String>> build() => ref.watch(activityStorageProvider).load();

  Future<void> record(String entry) {
    final entries = [...state.requireValue, entry];
    state = AsyncData(entries);
    return ref.read(activityStorageProvider).save(entries);
  }
}

/// The activity log, newest first. Requires [activityLogProvider] to be loaded.
@riverpod
List<String> recentActivity(Ref ref) =>
    ref.watch(activityLogProvider).requireValue.reversed.toList();
