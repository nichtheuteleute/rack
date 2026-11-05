import 'disposable.dart';

/// Base class for a Rack module: a typed bag of dependencies that share a
/// lifecycle.
///
/// Expose stores as `late final` fields wrapped in [use] — `late final` makes
/// them lazy and single-instance, [use] registers them for disposal.
///
/// A module takes the modules it needs as constructor arguments and names
/// them again in [dependsOn], which every module must pass to this
/// constructor:
///
/// ```dart
/// class FilesModule extends RackModule {
///   FilesModule(this.settings) : super(dependsOn: [settings]);
///   final SettingsModule settings;
/// }
///
/// class SettingsModule extends RackModule {
///   SettingsModule() : super(dependsOn: const []);
/// }
/// ```
abstract class RackModule implements Disposable {
  /// Creates a module that depends on the modules in [dependsOn].
  RackModule({required List<RackModule> dependsOn})
      : dependsOn = List.unmodifiable(dependsOn);

  /// The modules this module needs — usually exactly its module constructor
  /// arguments; `const []` if it needs none.
  ///
  /// `RackProvider` uses it to
  /// - run this module's [init] only after theirs has completed, and run
  ///   independent modules in parallel,
  /// - register a dependency that is not listed in the provider (or provided
  ///   by a parent provider) automatically.
  final List<RackModule> dependsOn;

  final List<void Function()> _disposers = [];

  /// Registers [instance] for disposal (if it is [Disposable]) and returns it.
  T use<T extends Object>(T instance) {
    if (instance is Disposable) _disposers.add(instance.dispose);
    return instance;
  }

  /// Optional async initialization, run by `RackProvider` before its subtree
  /// is built, after the [init] of every module in [dependsOn] has completed.
  Future<void> init() async {}

  @override
  void dispose() {
    for (final disposer in _disposers.reversed) {
      disposer();
    }
    _disposers.clear();
  }
}
