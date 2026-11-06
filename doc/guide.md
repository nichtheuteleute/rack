# rack guide

Details beyond the [README](../README.md).

## Async initialization

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

Modules are initialized one after another, **in the order they were created**. A dependency has to exist before it can be passed to a constructor, so it is always created — and initialized — first: `FilesModule.init()` above can rely on the settings being loaded, whatever the list order. Startup time is the sum of all `init()` calls; if two loads in one module are independent, run them together with `Future.wait`, and start network work after the first frame instead of in `init()`.

## Loading and error state

```dart
RackProvider(
  modules: [settings, files],
  loading: const SplashScreen(),                  // shown until all init() complete
  errorBuilder: (error) => StartupError(error),   // shown if an init() throws
  builder: () => const MyApp(),
)
```

The app renders `loading` while modules initialize; once all `init()` calls complete, `builder` is called. If an `init()` throws, initialization stops and `errorBuilder` receives a `StateError` naming the failing module (`"FilesModule.init() failed: …"`). Without `errorBuilder`, a plain `ErrorWidget` is shown. `loading` defaults to an empty widget.

## Screen-scoped modules

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
  Widget build(BuildContext context) {
    return RackProvider(
      modules: [_editor],
      builder: () => const _EditorView(),
    );
  }
}

class _EditorView extends RackWidget<EditorController> {
  const _EditorView();

  @override
  EditorController create(Rack rack) {
    return EditorController(
      filesStore: rack.module<FilesModule>().files,    // global — from the app-root provider
      searchStore: rack.module<EditorModule>().search, // scoped — from EditorScreen's provider
    );
  }

  @override
  Widget buildContent(BuildContext context, EditorController controller) {
    return EditorView(controller: controller);
  }
}
```

A nested `RackProvider` merges its parent's modules: parent modules stay accessible, and a nested module replaces a parent module of the same type.

Lifecycle: `EditorModule` is initialized when `EditorScreen` mounts and disposed when it unmounts. Modules of the parent provider are unaffected.

If a scoped module depends on a parent module, look the parent up with `Rack(context).module<T>()` and pass it to the constructor — e.g. in `didChangeDependencies` of the `State`.

## Testing

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
final settings = SettingsModule();
RackProvider(
  modules: [settings, FilesModule(settings, source: InMemoryFileSource())],
  builder: () => const FilesScreen(),
)
```

## Using rack with signals

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
  Widget build(BuildContext context) {
    return Text(controller.filter.value.name); // tracked
  }
}
```

Prefer these two over the `Watch` widget and `.watch(context)`, which are deprecated in signals 7.

**3. Optional: make every screen reactive by default.** If you'd rather not think about it per screen, define a base class once in your app and use it instead of `RackWidget`:

```dart
abstract class SignalRackWidget<C extends Object> extends RackWidget<C> {
  const SignalRackWidget({super.key});

  Widget buildReactive(BuildContext context, C controller);

  @override
  Widget buildContent(BuildContext context, C controller) {
    return SignalBuilder(
      builder: (context) => buildReactive(context, controller),
    );
  }
}
```

This tracks reads directly in `buildReactive` and rebuilds the whole screen on every change. Child widgets still need rule 2.

**4. Catch forgotten wraps with a test.** A widget test that changes a signal and expects the new value on screen fails if a read is not tracked:

```dart
controller.count.value = 1;
await tester.pump();
expect(find.text('1'), findsOneWidget);
```
