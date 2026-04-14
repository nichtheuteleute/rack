import '../core/rack_registry.dart';

abstract class RackModule {
  void register(RackRegistry registry);
}
