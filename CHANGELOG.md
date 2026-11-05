## 0.1.0

Initial release.

- `RackModule`: typed container for services with optional async `init()`.
  `use()` registers services for disposal; module dependencies are
  constructor arguments.
- `RackProvider`: initializes modules in order — or in parallel where
  modules declare their dependencies with `RackModule.dependsOn` — registers
  declared dependencies that are not listed, rejects two instances of one
  module type, shows `loading` /
  `errorBuilder` while starting up, disposes modules on unmount. Providers can
  be nested to scope modules to a subtree.
- `RackWidget`: creates one controller per widget and disposes it on
  unmount. Works with any state approach (signals, `ValueNotifier`, streams).
- `Rack`: looks up modules with `module<T>()` / `moduleOrNull<T>()`.
- `Disposable`: cleanup contract for services, modules and controllers.
- No dependencies besides Flutter.
