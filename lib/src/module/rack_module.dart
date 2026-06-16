import 'rack_setup.dart';

abstract class RackModule {
  const RackModule();

  static RackModule instance<T extends Object>(T value) => _InstanceModule<T>(value);

  Future<void> setup(RackSetup rack) async {}
}

class _InstanceModule<T extends Object> implements RackModule {
  final T _value;
  const _InstanceModule(this._value);

  @override
  Future<void> setup(RackSetup rack) async => rack.register<T>(_value);
}
