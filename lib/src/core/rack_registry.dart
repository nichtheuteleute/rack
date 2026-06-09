import 'rack_bindings.dart';

class RackRegistry {
  final RackBindings _bindings;

  RackRegistry(this._bindings);

  void register<T extends Object>(
    T Function() create, {
    void Function(T value)? dispose,
  }) {
    _bindings.add(create, dispose: dispose);
  }
}
