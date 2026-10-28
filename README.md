# Rack

Lightweight DI + controller lifecycle for Flutter. No code generation, no ChangeNotifier, no boilerplate.

Rack does two things:
1. **Groups services into modules** (stores, sources, clients) that are created once, optionally initialized async at app start, and disposed together.
2. **Binds controllers to screens** — each screen gets its own controller instance, created and disposed automatically.

State management is not Rack's job. `RackWidget` builds inside a [signals](https://pub.dev/packages/signals_flutter) `Watch`, so reading a signal in `buildContent` rebuilds the widget automatically. Your stores can still use streams or plain Dart.

---

## Core Concepts

| Piece | What it does |
|---|---|
| `RackModule` | A typed bag of services that share a lifecycle. Supports async `init()`. |
| `use(...)` | Registers a module field for disposal. Combine with `late final` for lazy, single-instance services. |
| `RackProvider` | Composition root. Initializes its modules, then exposes them to the subtree. |
| `RackWidget<C>` | Base class for screens/views that need a controller. |
| `Rack` | Passed to `create()` — use `rack.module<T>()` to look up a module. |
| `Disposable` | Implement on services, controllers or modules that need cleanup. |

---

## Use Cases

### 1. Define a module

```dart
class SettingsModule extends RackModule {
  late final settings = use(SettingsStore());
}
```

`late final` makes the store lazy and single-instance: it is created on first access, and every later access returns the same instance. `use()` registers it for disposal — if it implements `Disposable`, it is disposed when the module is disposed. A store that is never read is never created.

Mount at app root:

```dart
final settingsModule = SettingsModule();

RackProvider(
  modules: [settingsModule],
  builder: () => const MyApp(),
)
```

`RackProvider` takes already-created module instances. Create them once (top-level, in `main()` or in a `State`) — not inside a `build` method.

---

### 2. A module that depends on another module

A module declares its dependencies as constructor arguments. The dependency is checked by the compiler, not looked up at runtime:

```dart
class FilesModule extends RackModule {
  FilesModule(this.settings);
  final SettingsModule settings;

  late final files = use(FilesStore(settings: settings.settings));
}
```

```dart
final settings = SettingsModule();
final files = FilesModule(settings);

RackProvider(
  modules: [settings, files], // dependencies first
  builder: () => const MyApp(),
)
```

---

### 3. Async initialization

Override `init()` for work that needs async I/O before the app is usable (auth tokens, file handles, remote config):

```dart
class FilesModule extends RackModule {
  FilesModule(this.settings);
  final SettingsModule settings;

  late final FileSource source;
  late final files = use(FilesStore(fileSource: source));

  @override
  Future<void> init() async {
    final s = settings.settings.value;
    source = use(
      s.useCloudStorage
          ? await CloudFileSource.create(token: s.token)
          : await LocalFileSource.create(),
    );
  }
}
```

Modules are initialized sequentially, in list order — each `init()` is awaited before the next one starts. List a module after the modules it depends on, so their `init()` has completed before its own runs.

---

### 4. Loading and error state

```dart
RackProvider(
  modules: [settings, files],
  loading: const SplashScreen(),                  // shown until all init() complete
  errorBuilder: (error) => StartupError(error),   // shown if an init() throws
  builder: () => const MyApp(),
)
```

The app renders `loading` while modules initialize; once all `init()` calls complete, `builder` is called. If an `init()` throws, initialization stops and `errorBuilder` receives a `StateError` naming the failing module (`"FilesModule.init() failed: …"`). Without `errorBuilder`, a plain `ErrorWidget` is shown. `loading` defaults to an empty widget.

---

### 5. Screen controller with automatic lifecycle

```dart
class SidebarController implements Disposable {
  final FilesStore filesStore;

  SidebarController({required this.filesStore});

  void openFile(MarkdownFile file) => filesStore.openFile(file.id);
  void createFile(String name) => filesStore.createFile(name: name);

  @override
  void dispose() {}
}

class AppSidebar extends RackWidget<SidebarController> {
  const AppSidebar({super.key});

  @override
  SidebarController create(Rack rack) => SidebarController(
    filesStore: rack.module<FilesModule>().files,
  );

  @override
  Widget buildContent(BuildContext context, SidebarController controller) {
    return FileTree(
      files: controller.filesStore.fileTree.value, // signal read → auto rebuild
      onTap: controller.openFile,
    );
  }
}
```

`create()` is called once when the widget mounts. If the controller implements `Disposable`, `dispose()` is called when it unmounts. The controller is never recreated on rebuild.

`rack.module<T>()` throws a `StateError` naming the type if no such module is provided. Use `rack.moduleOrNull<T>()` for optional modules.

---

### 6. Events stay in the controller — no callbacks up the tree

```
Widget → calls controller method → controller calls store → store updates signal → Widget rebuilds
```

No `onTap: (file) => setState(...)` bubbling up through three widget layers. No callbacks passed as constructor arguments through the tree. The controller is the only place that knows about stores.

---

### 7. Screen-scoped modules

Some services belong to a screen, not the whole app — a search store, a form state, a local selection. Nest a second `RackProvider` to provide screen-local modules:

```dart
class EditorModule extends RackModule {
  late final search = use(EditorSearchStore());
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _editor = EditorModule(); // created once, not on every build

  @override
  Widget build(BuildContext context) => RackProvider(
    modules: [_editor],
    builder: () => const _EditorView(),
  );
}

class _EditorView extends RackWidget<EditorController> {
  const _EditorView();

  @override
  EditorController create(Rack rack) => EditorController(
    filesStore: rack.module<FilesModule>().files,       // global — from the app-root provider
    searchStore: rack.module<EditorModule>().search,    // scoped — from EditorScreen's provider
  );

  @override
  Widget buildContent(BuildContext context, EditorController controller) => …;
}
```

A nested `RackProvider` merges its parent's modules: parent modules stay accessible, and a nested module replaces a parent module of the same type.

Lifecycle: `EditorModule` is initialized when `EditorScreen` mounts and disposed when it unmounts. Modules of the parent provider are unaffected.

If a scoped module depends on a parent module, look the parent up with `Rack(context).module<T>()` and pass it to the constructor — e.g. in `didChangeDependencies` of the `State`.

---

### 8. Testing

Controllers are plain Dart — test them by constructing them with fake stores, no widget tree needed.

For widget tests, wrap the widget in a `RackProvider` with the modules it looks up. Modules are keyed by their **runtime type**, so `rack.module<FilesModule>()` does not find a subclass like `FakeFilesModule`. Make a module testable by letting its constructor accept fakes instead:

```dart
class FilesModule extends RackModule {
  FilesModule(this.settings, {FileSource? source}) : _override = source;
  final SettingsModule settings;
  final FileSource? _override;

  late final FileSource source;
  late final files = use(FilesStore(fileSource: source));

  @override
  Future<void> init() async {
    source = _override ?? use(await LocalFileSource.create());
  }
}

// In a widget test:
RackProvider(
  modules: [FilesModule(SettingsModule(), source: InMemoryFileSource())],
  builder: () => const AppSidebar(),
)
```

---

## Compared to the alternatives

### vs. Provider

Provider's DI mechanism IS the widget tree — every `context.read<T>()` traverses it. Business logic ends up scattered across widgets because the only way to get a dependency is through a `BuildContext`.

Rack separates concerns: modules hold services, controllers receive them at creation time, widgets call methods. No `context.read<T>()` in build methods, and module-to-module dependencies are plain constructor arguments.

### vs. Riverpod

Riverpod requires code generation (`.g.dart` files) for any non-trivial setup, and auto-dispose scoping requires understanding provider families and lifetimes. Testing needs `ProviderContainer` setup.

Rack has no generated code. Controller lifecycle is explicit — a controller exists exactly as long as its widget. Testing a controller is plain Dart: construct it with mock stores, call methods, assert on signal values.

### vs. Bloc

Bloc enforces an event → state → rebuild cycle for every interaction. A button tap needs: an `Event` class, a `state` variant, a `on<Event>` handler, a `BlocBuilder`, and often a `BlocListener` for side effects.

Rack controllers are plain Dart objects. A button tap is a method call. If you need reactive state, use a signal — no ceremony required.

---

## Rules

- **One module per type.** A `RackProvider` holds one instance per module runtime type. Nest a `RackProvider` to scope modules to a subtree.
- **Dependencies go through the constructor.** A module takes the modules it needs as constructor arguments and is listed after them in `RackProvider`.
- **Create modules once.** Pass instances that outlive rebuilds — never construct them inline in a `build` method.
- **No business logic in widgets.** Widgets call controller methods; controllers call stores. Never the other way.
- **Controllers get stores, not other controllers.** Shared state belongs in a store.
- **Wrap module services in `use()` and implement `Disposable` on anything that needs cleanup.** Module services are disposed in reverse creation order, modules in reverse list order, controllers when their widget unmounts.

## Decisions

- [ADR 001: Live-Lookup statt Snapshot im init()-Rack](docs/decisions/001-live-lookup-in-init.md) — superseded
- [ADR 002: Module als typisierte Container](docs/decisions/002-typed-modules.md)
