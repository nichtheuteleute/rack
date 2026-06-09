import '../core/rack_registry.dart';
import 'rack_injector.dart';

abstract class RackModule {
  void register(RackRegistry registry);

  /// Called after all sync [register] calls complete, in module order.
  /// Use [injector] to read previously registered services and [registry] to
  /// register services that require async setup.
  Future<void> init(RackInjector injector, RackRegistry registry) async {}
}
