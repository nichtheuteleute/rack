import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';
import '../module/rack_module.dart';

/// Composition root: initializes [modules] and provides them to the
/// subtree built by [builder].
///
/// Modules are initialized one after another in the order they were created.
/// A module's dependencies are passed to its constructor, so they always
/// exist — and are initialized — before it. Until all `init()` calls have
/// completed, [loading] is shown; if one throws, [errorBuilder] is shown. The
/// modules are disposed in reverse order when the provider unmounts.
///
/// Every module that is used must be provided: a module that was created and
/// passed to another module but is not listed here is reported with a
/// [StateError] as soon as it is used. Two different instances of one module
/// type, or a module already provided by another `RackProvider`, are reported
/// through [errorBuilder].
///
/// Providers can be nested: a nested provider sees its parent's modules, and
/// its own modules replace parent modules of the same type.
class RackProvider extends StatefulWidget {
  /// The modules to provide, already instantiated, in any order. List every
  /// module the app uses, including those that are only passed to other
  /// modules.
  ///
  /// Read once when the provider mounts: the provider owns these instances
  /// and disposes them on unmount. Modules passed on a later rebuild are
  /// ignored.
  final List<RackModule> modules;

  /// Builds the subtree once all modules are initialized.
  final Widget Function() builder;

  /// Shown while modules are initializing. Defaults to an empty widget.
  final Widget loading;

  /// Shown when a module's init throws. Defaults to a plain error widget.
  final Widget Function(Object error)? errorBuilder;

  /// Creates a provider for [modules].
  const RackProvider({
    super.key,
    required this.modules,
    required this.builder,
    this.loading = const SizedBox.shrink(),
    this.errorBuilder,
  });

  @override
  State<RackProvider> createState() => _RackProviderState();
}

class _RackProviderState extends State<RackProvider> {
  /// The listed modules in creation order. The provider owns them.
  List<RackModule> _modules = const [];
  bool _initStarted = false;
  bool _initialized = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    setProviderMounted(true);
    final modules = widget.modules.toSet().toList()
      ..sort((a, b) => creationIndexOf(a).compareTo(creationIndexOf(b)));
    try {
      _check(modules);
    } catch (e) {
      _initError = e;
      return;
    }
    _modules = List.unmodifiable(modules);
    for (final module in _modules) {
      setProvided(module, true);
    }
  }

  /// Reports wiring mistakes before anything is initialized.
  void _check(List<RackModule> modules) {
    final byType = <Type, RackModule>{};
    for (final module in modules) {
      if (isProvided(module)) {
        throw StateError(
          '${module.runtimeType} is already provided by another '
          'RackProvider. List each module in one provider only.',
        );
      }
      if (byType.containsKey(module.runtimeType)) {
        throw StateError(
          'Two different ${module.runtimeType} instances in one RackProvider. '
          'Create the module once and pass the same instance to every module '
          'that depends on it.',
        );
      }
      byType[module.runtimeType] = module;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted && _initError == null) {
      _initStarted = true;
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      for (final module in _modules) {
        if (!mounted) return;
        try {
          await module.init();
        } catch (e) {
          throw StateError('${module.runtimeType}.init() failed: $e');
        }
      }
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e);
    }
  }

  @override
  void dispose() {
    for (final module in _modules.reversed) {
      setProvided(module, false);
      module.dispose();
    }
    setProviderMounted(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return widget.errorBuilder?.call(_initError!) ?? ErrorWidget(_initError!);
    }
    if (!_initialized) return widget.loading;

    final parent = context.getInheritedWidgetOfExactType<RackInherited>();
    final modules = <Type, RackModule>{
      if (parent != null) ...parent.modules,
      for (final module in _modules) module.runtimeType: module,
    };
    return RackInherited(
      modules: modules,
      child: widget.builder(),
    );
  }
}
