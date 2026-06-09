import '../core/rack_registry.dart';
import '../module/rack_module.dart';

class AuthModule extends RackModule {
  @override
  void register(RackRegistry registry) {
    registry.register<AuthStore>(() => AuthStore());
  }
}

class UserModule extends RackModule {
  @override
  void register(RackRegistry registry) {
    registry.register<UserStore>(() => UserStore());
  }
}

// Placeholder stores
class AuthStore {}

class UserStore {}
