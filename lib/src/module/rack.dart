import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';

class Rack {
  final BuildContext _context;

  Rack(BuildContext context) : _context = context;

  T read<T extends Object>() => RackInherited.of(_context).get<T>();
}
