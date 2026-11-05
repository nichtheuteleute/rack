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

  /// Optional async initialization, run by `RackProvider` before its subtree
  /// is built. When it runs relative to other modules is controlled by
  /// [dependsOn].
  Future<void> init() async {}

  /// The modules whose [init] must complete before this module's [init]
  /// starts.
  ///
  /// `null` (the default) means: all modules listed before this one in the
  /// same `RackProvider` — modules are initialized one after another, in list
  /// order.
  ///
  /// Return an explicit list to let modules initialize in parallel: a module
  /// starts as soon as the modules it lists have finished, independent
  /// modules start at the same time. Usually this lists the modules taken as
  /// constructor arguments:
  ///
  /// ```dart
  /// class FilesModule extends RackModule {
  ///   FilesModule(this.settings);
  ///   final SettingsModule settings;
  ///
  ///   @override
  ///   List<RackModule> get dependsOn => [settings];
  /// }
  /// ```
  ///
  /// Return `const []` for a module that depends on nothing. Modules that are
  /// not part of the same `RackProvider` (e.g. provided by a parent provider)
  /// are already initialized and are ignored.
  List<RackModule>? get dependsOn => null;

  @override
  void dispose() {
    for (final disposer in _disposers.reversed) {
      disposer();
    }
    _disposers.clear();
  }
}
