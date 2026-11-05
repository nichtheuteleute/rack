# Rack

Lightweight DI + controller lifecycle for Flutter. No code generation, no ChangeNotifier, no boilerplate.

Rack does two things:
1. **Groups services into modules** (stores, sources, clients) that are created once, optionally initialized async at app start, and disposed together.
2. **Binds controllers to screens** — each screen gets its own controller instance, created and disposed automatically.

State management is not Rack's job, and Rack has no dependencies besides Flutter. Your stores can use [signals](https://pub.dev/packages/signals_flutter), `ValueNotifier`, streams or plain Dart — wrap the part of the UI that reads them in the matching builder (`SignalBuilder`, `ValueListenableBuilder`, `StreamBuilder`). The examples below use signals; see [Using Rack with signals](#using-rack-with-signals) for the recommended setup.

## Why Rack

- **Small enough to read completely.** About 160 lines of code in six classes (roughly 2,000 tokens). You, a reviewer or an AI coding agent can read the whole library instead of guessing how it works. For comparison: flutter_bloc + bloc ≈ 1,100 lines, get_it ≈ 2,300, provider ≈ 2,500, flutter_riverpod + riverpod ≈ 9,500.
- **No dependencies, no code generation.** Only Flutter. No `build_runner`, no generated files to keep in sync, no version conflicts with the state library you choose.
- **Wiring mistakes surface early.** Module dependencies are constructor arguments, so forgetting one is a compile error. We removed every wiring step, one at a time, from the same app built with rack, Riverpod, Bloc and provider: with rack, every dependency between modules was caught by the compiler, dependencies cannot be left unregistered, and the one remaining runtime case fails at startup with a message naming the missing module. With Bloc and provider, a forgotten link between two features compiled fine and the app silently showed stale data ([details](tool/wiring_check/RESULTS.md)).
- **Negligible overhead.** Mounting a screen with its controller costs about 0.8 µs — 0.15 µs more than a hand-written `StatefulWidget`, and about 40 % less than the usual provider pattern ([benchmark](tool/benchmark/README.md)).
- **Easy for AI coding agents to pick up.** The whole library fits into about 2,000 tokens. In a benchmark of 90 Claude Code runs on the same app built with rack, Riverpod and Bloc, agents solved all 30 rack tasks without ever opening rack's documentation — the project's own README was enough. rack did not make agents cheaper, though: token cost was on par with Riverpod on small changes and higher when a new dependency between features had to be wired ([method and results](tool/agent_bench/RESULTS.md)).

## Installation

```sh
flutter pub add rack
```

```dart
import 'package:rack/rack.dart';
```

A runnable app (using signals) is in [`example/`](example/lib/main.dart).

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
  SettingsModule() : super(dependsOn: const []);

  late final settings = use(SettingsStore());
}
```

Every module states the modules it depends on in `dependsOn` — `const []` if none. It is a required constructor parameter: a module without it does not compile.

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

A module takes the modules it needs as constructor arguments and names them in `dependsOn`, right next to them. The dependency is checked by the compiler, not looked up at runtime:

```dart
class FilesModule extends RackModule {
  FilesModule(this.settings) : super(dependsOn: [settings]);
  final SettingsModule settings;

  late final files = use(FilesStore(settings: settings.settings));
}
```

```dart
final settings = SettingsModule();
final files = FilesModule(settings);

RackProvider(
  modules: [files], // settings is registered through FilesModule.dependsOn
  builder: () => const MyApp(),
)
```

`RackProvider` registers every module named in `dependsOn` that is not listed (and not provided by a parent provider) itself: it is initialized, can be looked up with `rack.module<T>()` and is disposed with the provider. So a dependency can never be left uninitialized. Listing it as well does no harm; list order does not matter. Two different instances of the same module type in one provider — usually a module created twice by mistake — are reported through `errorBuilder`.

---

### 3. Async initialization

Override `init()` for work that needs async I/O before the app is usable (auth tokens, file handles, remote config):

```dart
class FilesModule extends RackModule {
  FilesModule(this.settings) : super(dependsOn: [settings]);
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

A module's `init()` starts as soon as the `init()` of every module in its `dependsOn` has completed — `FilesModule.init()` above can rely on the settings being loaded. Modules that do not depend on each other initialize in parallel: five independent modules that each load for 50 ms take 50 ms, not 250 ms.

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
    return SignalBuilder(
      builder: (context) => FileTree(
        files: controller.filesStore.fileTree.value, // signal read → rebuild
        onTap: controller.openFile,
      ),
    );
  }
}
```

`create()` is called once when the widget mounts. If the controller implements `Disposable`, `dispose()` is called when it unmounts. The controller is never recreated on rebuild.

`buildContent` is a plain build method — Rack does not track state reads. Wrap the parts that read reactive state in a builder, as close to the read as possible, so only they rebuild. See [Using Rack with signals](#using-rack-with-signals).

`rack.module<T>()` throws a `StateError` naming the type if no such module is provided. Use `rack.moduleOrNull<T>()` for optional modules.

---

### 6. Events stay in the controller — no callbacks up the tree

```
Widget → calls controller method → controller calls store → store updates signal → SignalBuilder rebuilds
```

No `onTap: (file) => setState(...)` bubbling up through three widget layers. No callbacks passed as constructor arguments through the tree. The controller is the only place that knows about stores.

---

### 7. Screen-scoped modules

Some services belong to a screen, not the whole app — a search store, a form state, a local selection. Nest a second `RackProvider` to provide screen-local modules:

```dart
class EditorModule extends RackModule {
  EditorModule() : super(dependsOn: const []);

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
  FilesModule(this.settings, {FileSource? source})
      : _override = source,
        super(dependsOn: [settings]);
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

## Using Rack with signals

Rack and [signals](https://pub.dev/packages/signals_flutter) are a good fit: modules own the stores, stores expose signals, controllers change them. Rack itself does not depend on signals, so you pick the version and decide where the UI reacts. The recommendations below need `signals_flutter` 7 or later.

**The pitfall:** a signal read in a plain `build` or `buildContent` is not tracked. The UI shows the value once and then silently stays stale — no error, no lint. Every signal read in the UI must happen inside one of the following.

**1. In a screen: `SignalBuilder` around the part that reads.** Keep it small — only the wrapped part rebuilds.

```dart
@override
Widget buildContent(BuildContext context, CounterController controller) {
  return Scaffold(
    appBar: AppBar(title: const Text('Counter')), // never rebuilds
    body: SignalBuilder(
      builder: (context) => Text('${controller.count.value}'),
    ),
  );
}
```

**2. In child widgets: extend `SignalWidget` instead of `StatelessWidget`.** Signals read in its `build` are tracked, and only that widget rebuilds. Use `SignalStatefulWidget` for stateful ones.

```dart
class _FilterChip extends SignalWidget {
  const _FilterChip({required this.controller});
  final NotesController controller;

  @override
  Widget build(BuildContext context) =>
      Text(controller.filter.value.name); // tracked
}
```

Prefer these two over the `Watch` widget and `.watch(context)`, which are deprecated in signals 7.

**3. Optional: make every screen reactive by default.** If you'd rather not think about it per screen, define a base class once in your app and use it instead of `RackWidget`:

```dart
abstract class SignalRackWidget<C extends Object> extends RackWidget<C> {
  const SignalRackWidget({super.key});

  Widget buildReactive(BuildContext context, C controller);

  @override
  Widget buildContent(BuildContext context, C controller) =>
      SignalBuilder(builder: (context) => buildReactive(context, controller));
}
```

This tracks reads directly in `buildReactive` and rebuilds the whole screen on every change. Child widgets still need rule 2.

**4. Catch forgotten wraps with a test.** A widget test that changes a signal and expects the new value on screen fails if a read is not tracked:

```dart
controller.count.value = 1;
await tester.pump();
expect(find.text('1'), findsOneWidget);
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

- **One module per type.** A `RackProvider` holds one instance per module runtime type; two different instances are an error. Nest a `RackProvider` to scope modules to a subtree.
- **Dependencies go through the constructor — and into `dependsOn`.** A module takes the modules it needs as constructor arguments and names exactly those in `super(dependsOn: [...])`. The compiler enforces that `dependsOn` is given; keeping it complete is on you, so write it on the same line as the constructor.
- **Create modules once.** Pass instances that outlive rebuilds — never construct them inline in a `build` method.
- **No business logic in widgets.** Widgets call controller methods; controllers call stores. Never the other way.
- **Controllers get stores, not other controllers.** Shared state belongs in a store.
- **Every reactive read in the UI is wrapped.** Read signals (or notifiers, streams) only inside a builder or a reactive widget like `SignalWidget` — Rack does not track reads, so an unwrapped read never rebuilds.
- **Wrap module services in `use()` and implement `Disposable` on anything that needs cleanup.** Module services are disposed in reverse creation order, modules in reverse dependency order, controllers when their widget unmounts.

## Decisions

- [ADR 001: Live-Lookup statt Snapshot im init()-Rack](doc/decisions/001-live-lookup-in-init.md) — superseded
- [ADR 002: Module als typisierte Container](doc/decisions/002-typed-modules.md)
- [ADR 003: Keine Abhängigkeit zu signals](doc/decisions/003-no-signals-dependency.md)
- [ADR 004: Parallele Initialisierung über `dependsOn`](doc/decisions/004-parallel-init.md)
- [ADR 005: Deklarierte Abhängigkeiten automatisch registrieren](doc/decisions/005-auto-register-dependencies.md)
- [ADR 006: `dependsOn` ist Pflicht](doc/decisions/006-required-depends-on.md)

## License

MIT — see [LICENSE](LICENSE).
