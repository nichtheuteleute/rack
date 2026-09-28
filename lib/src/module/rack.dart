import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';
import 'rack_module.dart';

/// Reads modules from the widget tree. Passed to `RackWidget.create`.
class Rack {
  final BuildContext _context;

  Rack(BuildContext context) : _context = context;

  /// Returns the module of type [T], or throws if it is not registered.
  T module<T extends RackModule>() => RackInherited.of(_context).module<T>();

  /// Returns the module of type [T], or `null` if it is not registered —
  /// the caller decides how to handle its absence.
  T? moduleOrNull<T extends RackModule>() =>
      RackInherited.of(_context).moduleOrNull<T>();
}
