import 'disposable.dart';

int _nextCreationIndex = 0;
int _mountedProviders = 0;

/// Base class for a Rack module: a typed bag of dependencies that share a
/// lifecycle.
///
/// Expose stores as `late final` fields wrapped in [use] — `late final` makes
/// them lazy and single-instance, [use] registers them for disposal.
///
/// A module takes the modules it needs as constructor arguments — nothing
/// else to declare:
///
/// ```dart
/// class FilesModule extends RackModule {
///   FilesModule(this.settings);
///   final SettingsModule settings;
/// }
/// ```
///
/// A dependency has to exist before it can be passed to a constructor, so it
/// is always created first. `RackProvider` initializes modules in creation
/// order, which therefore always runs a module's [init] after the [init] of
/// every module it depends on.
abstract class RackModule implements Disposable {
  final int _creationIndex = _nextCreationIndex++;
  int _providers = 0;

  final List<void Function()> _disposers = [];

  /// Registers [instance] for disposal (if it is [Disposable]) and returns it.
  ///
  /// Throws a [StateError] if this module is used while a `RackProvider` is
  /// mounted but no `RackProvider` provides it: its [init] never ran, and it
  /// would never be disposed. That is a module that was created and passed
  /// on, but not listed in `RackProvider.modules`.
  T use<T extends Object>(T instance) {
    if (_providers == 0 && _mountedProviders > 0) {
      throw StateError(
        '$runtimeType is used, but no RackProvider provides it, so its '
        'init() never ran. Add it to RackProvider.modules.',
      );
    }
    if (instance is Disposable) _disposers.add(instance.dispose);
    return instance;
  }

  /// Optional async initialization, run by `RackProvider` before its subtree
  /// is built — after the [init] of every module created before this one.
  Future<void> init() async {}

  @override
  void dispose() {
    for (final disposer in _disposers.reversed) {
      disposer();
    }
    _disposers.clear();
  }
}

// Internal API for RackProvider; hidden from the public library.

/// Position of [module] in the global creation order.
int creationIndexOf(RackModule module) => module._creationIndex;

/// Whether some RackProvider currently provides [module].
bool isProvided(RackModule module) => module._providers > 0;

/// Records that a RackProvider starts or stops providing [module].
void setProvided(RackModule module, bool provided) =>
    module._providers += provided ? 1 : -1;

/// Records that a RackProvider was mounted or unmounted.
void setProviderMounted(bool mounted) => _mountedProviders += mounted ? 1 : -1;
