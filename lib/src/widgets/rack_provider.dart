import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';
import '../module/rack_module.dart';

/// Composition root: initializes [modules] and provides them to the
/// subtree built by [builder].
///
/// Each module's `init()` is awaited in list order. Until all of them have
/// completed, [loading] is shown; if one throws, [errorBuilder] is shown.
/// The modules are disposed in reverse order when the provider unmounts.
///
/// Providers can be nested: a nested provider sees its parent's modules, and
/// its own modules replace parent modules of the same type.
class RackProvider extends StatefulWidget {
  /// The modules to provide, already instantiated. A module that depends on
  /// another takes it as a constructor argument and must be listed after it.
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
  late final List<RackModule> _modules = List.unmodifiable(widget.modules);
  bool _initStarted = false;
  bool _initialized = false;
  Object? _initError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted) {
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
      module.dispose();
    }
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
