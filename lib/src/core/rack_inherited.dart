import 'package:flutter/widgets.dart';
import '../module/rack_module.dart';

/// Holds the modules available to the widget subtree, keyed by each module's
/// runtime type. Nested providers merge their parent's modules in.
class RackInherited extends InheritedWidget {
  final Map<Type, RackModule> modules;

  const RackInherited({
    super.key,
    required this.modules,
    required super.child,
  });

  /// Returns the module of type [T], or throws if it is not registered.
  T module<T extends RackModule>() {
    final module = modules[T];
    if (module == null) {
      throw StateError('No module of type $T registered in Rack');
    }
    return module as T;
  }

  /// Returns the module of type [T], or `null` if it is not registered —
  /// the caller decides how to handle its absence.
  T? moduleOrNull<T extends RackModule>() => modules[T] as T?;

  static RackInherited of(BuildContext context) {
    final inherited = context.getInheritedWidgetOfExactType<RackInherited>();
    assert(inherited != null, 'No RackProvider found in the widget tree');
    return inherited!;
  }

  @override
  bool updateShouldNotify(RackInherited oldWidget) => false;
}
