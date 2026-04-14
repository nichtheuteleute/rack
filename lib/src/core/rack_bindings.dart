import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RackBindings {
  final List<RackBinding> _bindings = [];

  void add<T>(T Function() create, {void Function(T value)? dispose}) {
    _bindings.add(RackBinding<T>(create: create, dispose: dispose));
  }

  List<RackBinding> get bindings => _bindings;
}

class RackBinding<T> {
  final T Function() create;
  final void Function(T value)? dispose;

  RackBinding({required this.create, this.dispose});

  Widget wrap(Widget child) {
    return Provider<T>(
      create: (_) => create(),
      dispose: (_, value) => dispose?.call(value),
      child: child,
    );
  }
}
