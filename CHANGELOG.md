## 0.1.0

Initial release.

- `RackModule`: typed container for services with optional async `init()`.
  `use()` registers services for disposal; module dependencies are
  constructor arguments.
- `RackProvider`: initializes modules in order, shows `loading` /
  `errorBuilder` while starting up, disposes modules on unmount. Providers can
  be nested to scope modules to a subtree.
- `RackWidget`: creates one controller per widget, disposes it on unmount and
  rebuilds when signals read in `buildContent` change (via `signals_flutter`).
- `Rack`: looks up modules with `module<T>()` / `moduleOrNull<T>()`.
- `Disposable`: cleanup contract for services, modules and controllers.
