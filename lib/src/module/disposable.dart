/// Implemented by anything that holds resources and needs explicit cleanup:
/// services registered with `RackModule.use`, modules, and controllers
/// created by `RackWidget.create`.
abstract class Disposable {
  /// Releases the resources held by this object. Called exactly once by Rack.
  void dispose();
}
