import 'package:flutter/widgets.dart';

class RackInherited extends InheritedWidget {
  final Map<Type, Object> services;

  const RackInherited({
    super.key,
    required this.services,
    required super.child,
  });

  T get<T extends Object>() {
    final service = services[T];
    assert(service != null, 'No service registered for type $T in Rack');
    return service as T;
  }

  static RackInherited of(BuildContext context) {
    final inherited = context.getInheritedWidgetOfExactType<RackInherited>();
    assert(inherited != null, 'No RackProvider found in the widget tree');
    return inherited!;
  }

  @override
  bool updateShouldNotify(RackInherited oldWidget) => false;
}
