import 'package:flutter/material.dart';
import '../core/rack_bindings.dart';
import '../core/rack_registry.dart';
import '../module/rack_module.dart';
import '../module/rack_injector.dart';

class RackProvider extends StatelessWidget {
  final List<RackModule> modules;
  final Widget Function(RackInjector injector) builder;

  const RackProvider({
    super.key,
    required this.modules,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final bindings = RackBindings();
    final registry = RackRegistry(bindings);

    // Register all modules
    for (final module in modules) {
      module.register(registry);
    }

    // Wrap widgets with Providers for all registered stores
    Widget current = Builder(
      builder: (context) => builder(RackInjector(context)),
    );

    // Apply providers in reverse order (last one wraps first)
    for (final binding in bindings.bindings.reversed) {
      current = binding.wrap(current);
    }

    return current;
  }
}
