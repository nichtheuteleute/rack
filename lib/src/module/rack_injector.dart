import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';

class RackInjector {
  final BuildContext? _context;
  final Object? Function(Type)? _lookup;

  RackInjector(BuildContext context) : _context = context, _lookup = null;

  RackInjector.fromLookup(Object? Function(Type type) lookup)
      : _context = null,
        _lookup = lookup;

  T read<T extends Object>() {
    if (_lookup != null) return _lookup(T) as T;
    return RackInherited.of(_context!).get<T>();
  }
}
