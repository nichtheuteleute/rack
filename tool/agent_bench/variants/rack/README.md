# notes_app — rack + signals

A small notes app (add, toggle, filter, sort newest first) built with
rack (local path dependency) for DI/lifecycle and `signals_flutter` 7 for state.

```sh
fvm flutter test      # acceptance test + feature tests
fvm flutter analyze
```

## Architecture

```
lib/main.dart            App: creates modules from the injected storages, mounts RackProvider
lib/data/, lib/keys.dart shared files (storages, Note, widget keys) — never edit
lib/features/<feature>/
  <feature>_module.dart      RackModule: owns the store (`late final x = use(...)`), loads it in init()
  <feature>_store.dart       app-wide state as signals + all mutations and persistence calls
  <feature>_controller.dart  per-screen logic and screen-local signals (filter, input, derived lists)
  <feature>_screen.dart      RackWidget<Controller>: create() wires the controller, buildContent() renders
  widgets/                   child widgets; they take the controller as a constructor argument
test/features/<feature>/  controller/store unit tests and RackProvider widget tests
```

**Providing state.** `_AppState` creates `SettingsModule` and `NotesModule(settings)` once and passes
them to `RackProvider(modules: [settings, notes])` above `MaterialApp`, so pushed routes see them too.
RackProvider awaits each `init()` in list order (loading the storages) and shows `AppKeys.loading` meanwhile.

**Reading state.** A screen's `create(Rack rack)` looks up stores with `rack.module<XModule>().x` and
passes them to its controller. Widgets only call controller methods and read its signals. Every
signal read in the UI must be tracked: wrap it in `SignalBuilder` (screens) or make the child widget a
`SignalWidget`. An untracked read renders once and then silently goes stale.

**Feature dependencies.** A module takes the modules it needs as constructor arguments and is listed
after them in `RackProvider`. `NotesModule(settings)` hands `SettingsStore` to `NotesStore`, whose
`notes` computed sorts by `newestFirst`. Controllers get stores, never other controllers.

**Where logic goes.** Shared/persistent state and rules (sorting, counting, saving) → store.
Screen-only state (filter, text input, `canAdd`, filtered list) → controller. Widgets: layout only.
Controllers that own resources implement `Disposable`; rack disposes them when the screen unmounts.

**Adding a feature `foo`.** 1) `features/foo/foo_store.dart` with signals + methods; 2) `FooModule`
with `late final foo = use(FooStore(...))`, dependencies as constructor args, `init()` if it loads data;
3) create it in `_AppState` and add it to `RackProvider.modules` after its dependencies;
4) `FooScreen extends RackWidget<FooController>`; 5) tests: controller as plain Dart with real stores
over in-memory storages, screen in a `RackProvider` with the module — change a signal, `pump()`,
expect the new value (catches untracked reads).
