import 'disposable.dart';

class RackSetup {
  final Map<Type, Object> _services;
  final List<void Function()> _disposers;
  final Map<Type, Object>? _parentServices;

  RackSetup(this._services, this._disposers, [this._parentServices]);

  T read<T extends Object>() {
    final result = _services[T] ?? _parentServices?[T];
    assert(result != null, 'No service registered for $T — check module order in RackProvider.');
    return result as T;
  }

  void register<T extends Object>(T instance, {void Function(T)? dispose}) {
    _services[T] = instance;
    if (dispose != null) {
      _disposers.add(() => dispose(instance));
    } else if (instance is Disposable) {
      _disposers.add(instance.dispose);
    }
  }
}
