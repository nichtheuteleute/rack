import 'disposable.dart';

/// Base class for a Rack module: a typed bag of dependencies that share a
/// lifecycle.
///
/// Expose stores as `late final` fields wrapped in [use] — `late final` makes
/// them lazy and single-instance, [use] registers them for disposal. A module
/// declares its dependency on another module by taking it as a constructor
/// argument, so the dependency is compile-safe.
abstract class RackModule implements Disposable {
  final List<void Function()> _disposers = [];

  /// Registers [instance] for disposal (if it is [Disposable]) and returns it.
  T use<T extends Object>(T instance) {
    if (instance is Disposable) _disposers.add(instance.dispose);
    return instance;
  }

  /// Optional async initialization. Modules are initialized in the order they
  /// are listed in `RackProvider`; list a module after the ones it depends on.
  Future<void> init() async {}

  @override
  void dispose() {
    for (final disposer in _disposers.reversed) {
      disposer();
    }
    _disposers.clear();
  }
}
