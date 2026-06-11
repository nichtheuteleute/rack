# Rack

Lightweight DI + controller lifecycle for Flutter. No code generation, no ChangeNotifier, no boilerplate.

Rack does two things:
1. **Registers and initializes services** (stores, sources, clients) once at app start via modules.
2. **Binds controllers to screens** — each screen gets its own controller instance, created and disposed automatically.

State management is not Rack's job. Rack works with signals, streams, or plain Dart — whatever you use.

---

## Core Concepts

| Piece | What it does |
|---|---|
| `RackModule` | Groups related service registrations. Supports async `init()`. |
| `RackProvider` | Composition root. Mounts at the top of the widget tree. |
| `RackWidget<C>` | Base class for screens/views that need a controller. |
| `Rack` | Passed to `create()` and `init()` — use it to read registered services. |

---

## Use Cases

### 1. Register a global service

```dart
class SettingsModule extends RackModule {
  @override
  void register(RackRegistry r) {
    r.register<SettingsStore>(() => SettingsStore());
  }
}
```

Mount at app root:

```dart
RackProvider(
  modules: [SettingsModule(), FilesModule()],
  builder: () => const MyApp(),
)
```

Done. `SettingsStore` lives as long as the app. If it implements `Disposable`, it is disposed automatically when the app shuts down — no `dispose:` parameter needed.

---

### 2. Service that depends on another service

Use `init()` when setup requires an already-registered service:

```dart
class FilesModule extends RackModule {
  @override
  Future<void> init(Rack rack) async {
    final settings = rack.read<SettingsStore>();
    await rack.read<FilesStore>().init(settings.value);
  }
}
```

`init()` is called after all `register()` calls complete. If `SettingsStore` isn't registered yet, the app asserts at startup with a clear message — not silently later.

---

### 3. Async-constructed service (registerInstance)

Some services can't be created synchronously — they need async I/O before they're ready (auth tokens, file handles, remote config). Use `registerInstance` inside `init()` to register the fully-constructed instance directly, with no dummy placeholder required:

```dart
class FilesModule extends RackModule {
  @override
  Future<void> init(Rack rack) async {
    final settings = rack.read<SettingsStore>().settings.value;

    // Build the real instance asynchronously
    final source = settings.useCloudStorage
        ? await CloudFileSource.create(token: settings.token)
        : await LocalFileSource.create();

    // Register the finished instance — available to subsequent modules immediately
    rack.registerInstance<FilesStore>(FilesStore(fileSource: source));
  }
}
```

No `register()` override needed. No wrapper class to proxy the real object. The instance is written into the live service map, so any module that runs `init()` after this one can `read<FilesStore>()` and get the real thing.

This is not possible in `flutter_provider`, which separates `create` (sync, called once) from async side effects. Rack merges them into a single `init()` phase, making the async→register flow first-class.

---

### 4. Async initialization with loading state

```dart
RackProvider(
  modules: [SettingsModule(), FilesModule()],
  loading: const SplashScreen(),   // shown until all init() complete
  builder: () => const MyApp(),
)
```

The app renders `SplashScreen` while modules initialize. Once all `init()` calls complete, `MyApp` appears. No `FutureBuilder`, no manual state.

---

### 5. Screen controller with automatic lifecycle

```dart
class SidebarController implements Disposable {
  final FilesStore filesStore;
  final SettingsStore settingsStore;

  SidebarController({required this.filesStore, required this.settingsStore});

  void openFile(MarkdownFile file) => filesStore.openFile(file.id);
  void createFile(String name) => filesStore.createFile(name: name);

  @override
  void dispose() {}
}

class AppSidebar extends RackWidget<SidebarController> {
  @override
  SidebarController create(Rack rack) => SidebarController(
    filesStore: rack.read<FilesStore>(),
    settingsStore: rack.read<SettingsStore>(),
  );

  @override
  Widget buildContent(BuildContext context, SidebarController controller) {
    return FileTree(
      files: controller.filesStore.fileTree.value,
      onTap: controller.openFile,
    );
  }
}
```

`create()` is called once when the widget mounts. `dispose()` is called when it unmounts. The controller is never recreated on rebuild.

---

### 6. Events stay in the controller — no callbacks up the tree

```
Widget → calls controller method → controller calls store → store updates signal → Widget rebuilds
```

No `onTap: (file) => setState(...)` bubbling up through three widget layers. No callbacks passed as constructor arguments through the tree. The controller is the only place that knows about stores.

---

### 7. Screen-scoped services

Some services belong to a screen, not the whole app — a search store, a form state, a local selection. Nest a second `RackProvider` anywhere in the tree to add screen-local registrations:

```dart
class EditorModule extends RackModule {
  @override
  void register(RackRegistry r) {
    r.register<EditorSearchStore>(() => EditorSearchStore());
  }
}

class EditorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RackProvider(
    modules: [EditorModule()],
    builder: () => _EditorScreenInner(),
  );
}

class _EditorScreenInner extends RackWidget<EditorController> {
  @override
  EditorController create(Rack rack) => EditorController(
    filesStore: rack.read<FilesStore>(),          // global — from app-root RackProvider
    searchStore: rack.read<EditorSearchStore>(),   // scoped — from EditorScreen's RackProvider
  );
}
```

A nested `RackProvider` automatically merges its parent's services. Global services remain accessible — the inner provider only adds or overrides, it doesn't replace. Local services override global ones if the same type is registered in both.

Lifecycle: `EditorSearchStore` is created when `EditorScreen` mounts and disposed when it unmounts. `FilesStore` is unaffected.

This also makes overriding services in tests trivial:

```dart
// In a widget test: wrap with a RackProvider that provides a mock store
RackProvider(
  modules: [MockFilesModule()],
  builder: () => AppSidebar(),
)
```

---

## Compared to the alternatives

### vs. Provider

Provider's DI mechanism IS the widget tree — every `context.read<T>()` traverses it. Business logic ends up scattered across widgets because the only way to get a dependency is through a `BuildContext`.

Rack separates concerns: modules register services, controllers receive them at creation time, widgets call methods. No `context.read<T>()` in build methods.

### vs. Riverpod

Riverpod requires code generation (`.g.dart` files) for any non-trivial setup, and auto-dispose scoping requires understanding provider families and lifetimes. Testing needs `ProviderContainer` setup.

Rack has no generated code. Controller lifecycle is explicit — a controller exists exactly as long as its widget. Testing a controller is plain Dart: construct it with mock stores, call methods, assert on signal values.

### vs. Bloc

Bloc enforces an event → state → rebuild cycle for every interaction. A button tap needs: an `Event` class, a `state` variant, a `on<Event>` handler, a `BlocBuilder`, and often a `BlocListener` for side effects.

Rack controllers are plain Dart objects. A button tap is a method call. If you need reactive state, use a signal — no ceremony required.

---

## Rules

- **One service per type.** `RackProvider` holds one instance per registered type. Nest a `RackProvider` to scope services to a subtree.
- **No business logic in widgets.** Widgets call controller methods; controllers call stores. Never the other way.
- **Controllers get stores, not other controllers.** Shared state belongs in a store.
- **Implement `Disposable` on anything that needs cleanup.** Services and controllers are disposed automatically if they implement `Disposable`. No explicit `dispose:` callback needed at registration.
