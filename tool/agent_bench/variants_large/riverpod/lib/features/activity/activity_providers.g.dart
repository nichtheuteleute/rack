// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The activity persistence. `App` overrides it in the root `ProviderScope`.

@ProviderFor(activityStorage)
final activityStorageProvider = ActivityStorageProvider._();

/// The activity persistence. `App` overrides it in the root `ProviderScope`.

final class ActivityStorageProvider
    extends
        $FunctionalProvider<ActivityStorage, ActivityStorage, ActivityStorage>
    with $Provider<ActivityStorage> {
  /// The activity persistence. `App` overrides it in the root `ProviderScope`.
  ActivityStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityStorageHash();

  @$internal
  @override
  $ProviderElement<ActivityStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActivityStorage create(Ref ref) {
    return activityStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityStorage>(value),
    );
  }
}

String _$activityStorageHash() => r'58f01e429dce751278f9c1adaf62f8293cf98e22';

/// The activity log, oldest first. Other features add entries with [record];
/// every change is saved with [ActivityStorage.save].

@ProviderFor(ActivityLog)
final activityLogProvider = ActivityLogProvider._();

/// The activity log, oldest first. Other features add entries with [record];
/// every change is saved with [ActivityStorage.save].
final class ActivityLogProvider
    extends $AsyncNotifierProvider<ActivityLog, List<String>> {
  /// The activity log, oldest first. Other features add entries with [record];
  /// every change is saved with [ActivityStorage.save].
  ActivityLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityLogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityLogHash();

  @$internal
  @override
  ActivityLog create() => ActivityLog();
}

String _$activityLogHash() => r'4811757d45639f62a13134d82252277857248510';

/// The activity log, oldest first. Other features add entries with [record];
/// every change is saved with [ActivityStorage.save].

abstract class _$ActivityLog extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The activity log, newest first. Requires [activityLogProvider] to be loaded.

@ProviderFor(recentActivity)
final recentActivityProvider = RecentActivityProvider._();

/// The activity log, newest first. Requires [activityLogProvider] to be loaded.

final class RecentActivityProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// The activity log, newest first. Requires [activityLogProvider] to be loaded.
  RecentActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentActivityHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return recentActivity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentActivityHash() => r'd7d8b004ad0334f60d5029d96425ca04b5c894d7';
