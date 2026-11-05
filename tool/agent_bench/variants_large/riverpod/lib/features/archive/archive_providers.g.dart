// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The archive persistence. `App` overrides it in the root `ProviderScope`.

@ProviderFor(archiveStorage)
final archiveStorageProvider = ArchiveStorageProvider._();

/// The archive persistence. `App` overrides it in the root `ProviderScope`.

final class ArchiveStorageProvider
    extends $FunctionalProvider<ArchiveStorage, ArchiveStorage, ArchiveStorage>
    with $Provider<ArchiveStorage> {
  /// The archive persistence. `App` overrides it in the root `ProviderScope`.
  ArchiveStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveStorageHash();

  @$internal
  @override
  $ProviderElement<ArchiveStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveStorage create(Ref ref) {
    return archiveStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveStorage>(value),
    );
  }
}

String _$archiveStorageHash() => r'8d2316cdb14e49da9c93872d3885cfba6581ee81';

/// Archived notes, in archiving order. Moves notes between [notesProvider]
/// and the archive; both sides are saved.

@ProviderFor(Archive)
final archiveProvider = ArchiveProvider._();

/// Archived notes, in archiving order. Moves notes between [notesProvider]
/// and the archive; both sides are saved.
final class ArchiveProvider
    extends $AsyncNotifierProvider<Archive, List<Note>> {
  /// Archived notes, in archiving order. Moves notes between [notesProvider]
  /// and the archive; both sides are saved.
  ArchiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveHash();

  @$internal
  @override
  Archive create() => Archive();
}

String _$archiveHash() => r'ebd59a3cc37d0909622b37a935c53adaf8cb5873';

/// Archived notes, in archiving order. Moves notes between [notesProvider]
/// and the archive; both sides are saved.

abstract class _$Archive extends $AsyncNotifier<List<Note>> {
  FutureOr<List<Note>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Note>>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Note>>, List<Note>>,
              AsyncValue<List<Note>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
