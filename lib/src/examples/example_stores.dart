import '../module/disposable.dart';
import 'example_modules.dart';

class UserController implements Disposable {
  final AuthStore authStore;
  final UserStore userStore;

  UserController(this.authStore, this.userStore);

  String loadUser() => "User loaded";

  @override
  void dispose() {
    // Cleanup if needed
  }
}
