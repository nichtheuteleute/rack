// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The notes persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.

@ProviderFor(notesStorage)
final notesStorageProvider = NotesStorageProvider._();

/// The notes persistence. Has no default: `App` overrides it in the root
/// `ProviderScope`, tests override it in their container.

final class NotesStorageProvider
    extends $FunctionalProvider<NotesStorage, NotesStorage, NotesStorage>
    with $Provider<NotesStorage> {
  /// The notes persistence. Has no default: `App` overrides it in the root
  /// `ProviderScope`, tests override it in their container.
  NotesStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesStorageHash();

  @$internal
  @override
  $ProviderElement<NotesStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotesStorage create(Ref ref) {
    return notesStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotesStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotesStorage>(value),
    );
  }
}

String _$notesStorageHash() => r'2e7aedc1b251384f15c06f51d4abf22bb1cc7cc8';

/// All notes, in storage order. Every change is saved with [NotesStorage.save].

@ProviderFor(Notes)
final notesProvider = NotesProvider._();

/// All notes, in storage order. Every change is saved with [NotesStorage.save].
final class NotesProvider extends $AsyncNotifierProvider<Notes, List<Note>> {
  /// All notes, in storage order. Every change is saved with [NotesStorage.save].
  NotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesHash();

  @$internal
  @override
  Notes create() => Notes();
}

String _$notesHash() => r'a9d201d825e8f08b977f1d0a28742475589045c6';

/// All notes, in storage order. Every change is saved with [NotesStorage.save].

abstract class _$Notes extends $AsyncNotifier<List<Note>> {
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

/// The filter selected on the notes screen.

@ProviderFor(ActiveFilter)
final activeFilterProvider = ActiveFilterProvider._();

/// The filter selected on the notes screen.
final class ActiveFilterProvider
    extends $NotifierProvider<ActiveFilter, NoteFilter> {
  /// The filter selected on the notes screen.
  ActiveFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeFilterHash();

  @$internal
  @override
  ActiveFilter create() => ActiveFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteFilter>(value),
    );
  }
}

String _$activeFilterHash() => r'd142fe56693688f99cb336ae803112c3e6aef31a';

/// The filter selected on the notes screen.

abstract class _$ActiveFilter extends $Notifier<NoteFilter> {
  NoteFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoteFilter, NoteFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteFilter, NoteFilter>,
              NoteFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The notes to show: filtered by [activeFilterProvider], sorted by creation
/// time as set by [newestFirstProvider].
///
/// Requires [notesProvider] and [newestFirstProvider] to be loaded.

@ProviderFor(visibleNotes)
final visibleNotesProvider = VisibleNotesProvider._();

/// The notes to show: filtered by [activeFilterProvider], sorted by creation
/// time as set by [newestFirstProvider].
///
/// Requires [notesProvider] and [newestFirstProvider] to be loaded.

final class VisibleNotesProvider
    extends $FunctionalProvider<List<Note>, List<Note>, List<Note>>
    with $Provider<List<Note>> {
  /// The notes to show: filtered by [activeFilterProvider], sorted by creation
  /// time as set by [newestFirstProvider].
  ///
  /// Requires [notesProvider] and [newestFirstProvider] to be loaded.
  VisibleNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleNotesHash();

  @$internal
  @override
  $ProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Note> create(Ref ref) {
    return visibleNotes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Note> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Note>>(value),
    );
  }
}

String _$visibleNotesHash() => r'13c3ef72a1f2a79f6733e36ec86c5093077eee6a';

/// Number of notes not done. Requires [notesProvider] to be loaded.

@ProviderFor(openCount)
final openCountProvider = OpenCountProvider._();

/// Number of notes not done. Requires [notesProvider] to be loaded.

final class OpenCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Number of notes not done. Requires [notesProvider] to be loaded.
  OpenCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return openCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$openCountHash() => r'ed26e5f163c963b009ba53f333bf08c7cf5d6695';
