// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The profile persistence. `App` overrides it in the root `ProviderScope`.

@ProviderFor(profileStorage)
final profileStorageProvider = ProfileStorageProvider._();

/// The profile persistence. `App` overrides it in the root `ProviderScope`.

final class ProfileStorageProvider
    extends $FunctionalProvider<ProfileStorage, ProfileStorage, ProfileStorage>
    with $Provider<ProfileStorage> {
  /// The profile persistence. `App` overrides it in the root `ProviderScope`.
  ProfileStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStorageHash();

  @$internal
  @override
  $ProviderElement<ProfileStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileStorage create(Ref ref) {
    return profileStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileStorage>(value),
    );
  }
}

String _$profileStorageHash() => r'19d6408cd10c6ec86a9b7cedd2cc439d06980c00';

/// The user's name. Loaded from and saved to [ProfileStorage].

@ProviderFor(ProfileName)
final profileNameProvider = ProfileNameProvider._();

/// The user's name. Loaded from and saved to [ProfileStorage].
final class ProfileNameProvider
    extends $AsyncNotifierProvider<ProfileName, String> {
  /// The user's name. Loaded from and saved to [ProfileStorage].
  ProfileNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileNameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileNameHash();

  @$internal
  @override
  ProfileName create() => ProfileName();
}

String _$profileNameHash() => r'65bcb500233b35b6fbcb4f37ffc73f34432c587c';

/// The user's name. Loaded from and saved to [ProfileStorage].

abstract class _$ProfileName extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
