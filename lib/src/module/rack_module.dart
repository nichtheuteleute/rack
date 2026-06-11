import 'rack_setup.dart';

abstract class RackModule {
  Future<void> setup(RackSetup rack) async {}
}
