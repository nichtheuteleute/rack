// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The settings persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.

@ProviderFor(settingsStorage)
final settingsStorageProvider = SettingsStorageProvider._();

/// The settings persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.

final class SettingsStorageProvider
    extends
        $FunctionalProvider<SettingsStorage, SettingsStorage, SettingsStorage>
    with $Provider<SettingsStorage> {
  /// The settings persistence. Has no default: `App` overrides it in the root
  /// `ProviderScope`, tests override it in their container.
  SettingsStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStorageHash();

  @$internal
  @override
  $ProviderElement<SettingsStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsStorage create(Ref ref) {
    return settingsStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsStorage>(value),
    );
  }
}

String _$settingsStorageHash() => r'f316459bc12c317e9aa32a5206f60132cd737f55';

/// Whether notes are listed newest first. Loaded from and saved to
/// [SettingsStorage].

@ProviderFor(NewestFirst)
final newestFirstProvider = NewestFirstProvider._();

/// Whether notes are listed newest first. Loaded from and saved to
/// [SettingsStorage].
final class NewestFirstProvider
    extends $AsyncNotifierProvider<NewestFirst, bool> {
  /// Whether notes are listed newest first. Loaded from and saved to
  /// [SettingsStorage].
  NewestFirstProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newestFirstProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newestFirstHash();

  @$internal
  @override
  NewestFirst create() => NewestFirst();
}

String _$newestFirstHash() => r'7221f32353816d264e966a0c230b7dac11e3667c';

/// Whether notes are listed newest first. Loaded from and saved to
/// [SettingsStorage].

abstract class _$NewestFirst extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
