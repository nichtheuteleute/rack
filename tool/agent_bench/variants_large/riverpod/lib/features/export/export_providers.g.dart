// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The notes as a plain-text checklist, headed by the profile name, in the
/// current sort order (the notes screen's filter is ignored).

@ProviderFor(exportText)
final exportTextProvider = ExportTextProvider._();

/// The notes as a plain-text checklist, headed by the profile name, in the
/// current sort order (the notes screen's filter is ignored).

final class ExportTextProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The notes as a plain-text checklist, headed by the profile name, in the
  /// current sort order (the notes screen's filter is ignored).
  ExportTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportTextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportTextHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return exportText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$exportTextHash() => r'7a987a6ba3f11df6c22d9b0414a9108671904d1c';
