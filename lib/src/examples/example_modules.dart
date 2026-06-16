import '../module/rack_module.dart';
import '../module/rack_setup.dart';

class AuthStore {}

class UserStore {}

class AuthModule extends RackModule {
  @override
  Future<void> setup(RackSetup rack) async {
    rack.register<AuthStore>(AuthStore());
  }
}

class UserModule extends RackModule {
  @override
  Future<void> setup(RackSetup rack) async {
    rack.register<UserStore>(UserStore());
  }
}
