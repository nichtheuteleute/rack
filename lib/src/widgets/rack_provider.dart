import 'package:flutter/widgets.dart';
import '../core/rack_bindings.dart';
import '../core/rack_inherited.dart';
import '../core/rack_registry.dart';
import '../module/rack_injector.dart';
import '../module/rack_module.dart';

class RackProvider extends StatefulWidget {
  final List<RackModule> modules;
  final Widget Function() builder;

  /// Shown while modules are initializing. Defaults to an empty widget.
  final Widget loading;

  const RackProvider({
    super.key,
    required this.modules,
    required this.builder,
    this.loading = const SizedBox.shrink(),
  });

  @override
  State<RackProvider> createState() => _RackProviderState();
}

class _RackProviderState extends State<RackProvider> {
  final Map<Type, Object> _services = {};
  final List<void Function()> _disposers = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final bindings = RackBindings();
    for (final module in widget.modules) {
      module.register(RackRegistry(bindings));
    }
    for (final entry in bindings.entries) {
      _instantiate(entry);
    }
    _initModules();
  }

  void _instantiate(RackEntry entry) {
    final instance = entry.create();
    _services[entry.type] = instance;
    if (entry.dispose != null) {
      _disposers.add(() => entry.dispose!(instance));
    }
  }

  Future<void> _initModules() async {
    for (final module in widget.modules) {
      if (!mounted) return;
      final deferred = RackBindings();
      final injector = RackInjector.fromLookup((type) => _services[type]);
      await module.init(injector, RackRegistry(deferred));
      for (final entry in deferred.entries) {
        _instantiate(entry);
      }
    }
    if (mounted) setState(() => _initialized = true);
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
    if (!_initialized) return widget.loading;
    return RackInherited(
      services: _services,
      child: widget.builder(),
    );
  }
}
