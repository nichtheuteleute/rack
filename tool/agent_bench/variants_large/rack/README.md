# notes_app — rack + signals

A small notes app (notes, settings, profile, activity log, archive, export, search) built with
rack (local path dependency) for DI/lifecycle and `signals_flutter` 7 for state.

```sh
fvm flutter test      # acceptance test + feature tests
fvm flutter analyze
```

## Architecture

```
lib/main.dart          App: creates modules once per state from the injected storages, mounts RackProvider
lib/data/, lib/keys*.dart  shared files (storages, Note, widget keys) — never edit
lib/features/<feature>/
  <feature>_module.dart      RackModule: owns the store (`late final x = use(...)`), loads it in init()
  <feature>_store.dart       app-wide state as signals + all mutations and persistence calls
  <feature>_controller.dart  per-screen logic and screen-local signals (input, filter, derived values)
  <feature>_screen.dart      RackWidget<Controller>: create() wires the controller, buildContent() renders
  widgets/                   child widgets; they take the controller as a constructor argument
test/features/<feature>/  store/controller unit tests (plain Dart) and RackProvider widget tests
```
Stateful features: settings, profile, notes, activity, archive. Export and search own no state —
just a controller (computed over other stores) + screen, no module. Drawer: `notes/widgets/notes_drawer.dart`.

**Providing state.** `_AppState` creates all modules once and passes them, dependencies first, to
`RackProvider(modules: [settings, profile, notes, activity, archive])` above `MaterialApp` (pushed
routes see them too). Each `init()` is awaited in order; `AppKeys.loading` shows meanwhile.

**Reading state.** A screen's `create(Rack rack)` looks up stores via `rack.module<XModule>().x` and
passes them to its controller. Widgets only read controller signals and call its methods. Every signal
read in the UI must be inside `SignalBuilder` or a `SignalWidget` — an untracked read silently goes stale.

**Feature dependencies** (module constructor args): `NotesModule(settings)` — `NotesStore.notes` sorts
by `newestFirst`. `ArchiveModule(notes)` — `ArchiveStore` moves notes via `NotesStore.remove/insert`.
`ActivityModule(notes)` — `ActivityStore` listens to `NotesStore.events` (`NoteAdded`, `NoteCompleted`);
notes never knows about activity. Controllers may combine stores of several features (`NotesController`
gets `ArchiveStore`, `ExportController` gets profile + notes). Controllers never get other controllers.

**Where logic goes.** Shared/persistent state and rules (sorting, counting, saving, moving) → store.
Screen-only state (text input, filter, `canAdd`, search results, export text) → controller.
Widgets: layout only. Anything owning resources (TextEditingController, computeds, stream
subscriptions) implements `Disposable`: controllers die with their screen, stores with their module.

**Adding feature `foo`.** 1) `FooStore` with private signals, readonly getters, async mutations that
persist; 2) `FooModule` with `late final foo = use(FooStore(...))`, dependencies as constructor args,
`init()` to load; 3) create it in `_AppState`, list it after its dependencies; 4) `FooController` +
`FooScreen extends RackWidget<FooController>`, add a drawer entry; 5) tests as above — change a
signal, `pump()`, expect the new value (catches untracked reads).
