import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

// --- Services -------------------------------------------------------------

/// Pretend storage. In a real app this would wrap shared_preferences, a
/// database or a REST client.
class CounterStorage {
  int _saved = 0;

  Future<int> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _saved;
  }

  Future<void> save(int value) async => _saved = value;
}

/// App-wide state, exposed as a signal.
class CounterStore implements Disposable {
  CounterStore(this._storage);
  final CounterStorage _storage;

  final count = signal(0);

  Future<void> restore() async => count.value = await _storage.load();

  void increment() {
    count.value++;
    _storage.save(count.value);
  }

  @override
  void dispose() => count.dispose();
}

// --- Modules --------------------------------------------------------------

/// Infrastructure: created first, no dependencies.
class StorageModule extends RackModule {
  late final storage = use(CounterStorage());
}

/// Feature module: depends on [StorageModule] through its constructor and
/// restores its state asynchronously before the app is shown.
class CounterModule extends RackModule {
  CounterModule(this.storage);
  final StorageModule storage;

  late final counter = use(CounterStore(storage.storage));

  @override
  Future<void> init() => counter.restore();
}

// --- App ------------------------------------------------------------------

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Modules are created once and handed to RackProvider, which owns them.
  final _storage = StorageModule();
  late final _counter = CounterModule(_storage);

  @override
  Widget build(BuildContext context) {
    return RackProvider(
      modules: [_storage, _counter], // dependencies first
      // Shown until every init() has completed. RackProvider sits above
      // MaterialApp, so the spinner needs its own Directionality.
      loading: const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: () => const MaterialApp(home: CounterScreen()),
    );
  }
}

// --- Screen ---------------------------------------------------------------

/// Created once per [CounterScreen]; talks to the store so the widget does
/// not have to.
class CounterController {
  CounterController(this._store);
  final CounterStore _store;

  int get count => _store.count.value;
  void increment() => _store.increment();
}

class CounterScreen extends RackWidget<CounterController> {
  const CounterScreen({super.key});

  @override
  CounterController create(Rack rack) =>
      CounterController(rack.module<CounterModule>().counter);

  @override
  Widget buildContent(BuildContext context, CounterController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('rack example')),
      body: Center(
        // Rack does not rebuild on state changes by itself. Wrap exactly the
        // part that reads the signal, so only that part rebuilds.
        child: SignalBuilder(
          builder: (context) => Text(
            '${controller.count}',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
