## 0.1.0

Initial release.

- `RackModule`: typed container for services with optional async `init()`.
  `use()` registers services for disposal. Module dependencies are
  constructor arguments and are named in the required
  `super(dependsOn: [...])`.
- `RackProvider`: initializes each module as soon as its dependencies are
  done (independent modules in parallel), registers dependencies that are
  not listed, rejects two instances of one module type, shows `loading` /
  `errorBuilder` while starting up, disposes modules on unmount. Providers
  can be nested to scope modules to a subtree.
- `RackWidget`: creates one controller per widget and disposes it on
  unmount. Works with any state approach (signals, `ValueNotifier`, streams).
- `Rack`: looks up modules with `module<T>()` / `moduleOrNull<T>()`.
- `Disposable`: cleanup contract for services, modules and controllers.
- No dependencies besides Flutter.
