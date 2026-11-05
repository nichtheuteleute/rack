// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The text typed on the search screen. Reset when the screen closes.

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

/// The text typed on the search screen. Reset when the screen closes.
final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  /// The text typed on the search screen. Reset when the screen closes.
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'feb307a8e397761a174c13c2c102fff78abd4bf7';

/// The text typed on the search screen. Reset when the screen closes.

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Notes whose text contains the trimmed query, case-insensitive, in the
/// current sort order. Empty for an empty query.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Notes whose text contains the trimmed query, case-insensitive, in the
/// current sort order. Empty for an empty query.

final class SearchResultsProvider
    extends $FunctionalProvider<List<Note>, List<Note>, List<Note>>
    with $Provider<List<Note>> {
  /// Notes whose text contains the trimmed query, case-insensitive, in the
  /// current sort order. Empty for an empty query.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $ProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Note> create(Ref ref) {
    return searchResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Note> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Note>>(value),
    );
  }
}

String _$searchResultsHash() => r'10e1c0ccc239301e6f4aa09f855a4d43d7e26f0f';
