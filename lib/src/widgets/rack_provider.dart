import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';
import '../module/rack_module.dart';
import '../module/rack_setup.dart';

class RackProvider extends StatefulWidget {
  final List<RackModule> modules;
  final Widget Function() builder;

  /// Shown while modules are initializing. Defaults to an empty widget.
  final Widget loading;

  /// Shown when a module's setup throws. Defaults to a plain error widget.
  final Widget Function(Object error)? errorBuilder;

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
  final Map<Type, Object> _services = {};
  final List<void Function()> _disposers = [];
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
      final parent = context.getInheritedWidgetOfExactType<RackInherited>();
      final rackSetup = RackSetup(_services, _disposers, parent?.services);

      for (final module in widget.modules) {
        if (!mounted) return;
        try {
          await module.setup(rackSetup);
        } catch (e) {
          throw StateError(
            '${module.runtimeType}.setup() failed: $e\n'
            'Available: ${_services.keys.toList()}',
          );
        }
      }
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e);
    }
  }

  @override
  void dispose() {
    for (final disposer in _disposers.reversed) {
      disposer();
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
    final services = parent != null
        ? {...parent.services, ..._services}
        : _services;
    return RackInherited(
      services: services,
      child: widget.builder(),
    );
  }
}
