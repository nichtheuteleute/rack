import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RackInjector {
  final BuildContext context;

  RackInjector(this.context);

  T read<T>() => context.read<T>();
}
