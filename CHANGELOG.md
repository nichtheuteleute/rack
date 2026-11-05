## 0.1.1

- Shorter README; details moved to `doc/guide.md`.

## 0.1.0

Initial release.

- `RackModule`: typed container for services with optional async `init()`.
  `use()` registers services for disposal. Module dependencies are plain
  constructor arguments.
- `RackProvider`: initializes modules one after another in creation order
  (so dependencies always come first, whatever the list order), shows
  `loading` / `errorBuilder` while starting up and disposes modules on
  unmount. Reports wiring mistakes: a module that is used but not provided,
  two instances of one module type, a module listed in two providers.
  Providers can be nested to scope modules to a subtree.
- `RackWidget`: creates one controller per widget and disposes it on
  unmount. Works with any state approach (signals, `ValueNotifier`, streams).
- `Rack`: looks up modules with `module<T>()` / `moduleOrNull<T>()`.
- `Disposable`: cleanup contract for services, modules and controllers.
- No dependencies besides Flutter.
