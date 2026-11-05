// Runtime overhead of rack vs. plain Flutter vs. provider.
//
// Build in release mode and run the binary directly (see README.md). For each
// implementation, N screens that each own a controller are mounted, rebuilt
// with new widget instances, and unmounted. Each step is timed synchronously
// around BuildOwner.buildScope + finalizeTree, i.e. exactly the work of
// building/disposing widgets, without layout, paint or vsync waits.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rack/rack.dart';

const screens = 1000;
const warmup = 20;
const rounds = 200;
const moduleCount = 10;

// --- Shared services and controller ---------------------------------------

class Service {
  Service(this.id);
  final int id;
}

class Controller implements Disposable {
  Controller(this.service);
  final Service service;
  bool disposed = false;

  @override
  void dispose() => disposed = true;
}

// Ten distinct types, so lookups search among several registrations.
class S0 extends Service {
  S0() : super(0);
}

class S1 extends Service {
  S1() : super(1);
}

class S2 extends Service {
  S2() : super(2);
}

class S3 extends Service {
  S3() : super(3);
}

class S4 extends Service {
  S4() : super(4);
}

class S5 extends Service {
  S5() : super(5);
}

class S6 extends Service {
  S6() : super(6);
}

class S7 extends Service {
  S7() : super(7);
}

class S8 extends Service {
  S8() : super(8);
}

class S9 extends Service {
  S9() : super(9);
}

// --- rack -------------------------------------------------------------------

class M0 extends RackModule {
  late final s = use(S0());
}

class M1 extends RackModule {
  late final s = use(S1());
}

class M2 extends RackModule {
  late final s = use(S2());
}

class M3 extends RackModule {
  late final s = use(S3());
}

class M4 extends RackModule {
  late final s = use(S4());
}

class M5 extends RackModule {
  late final s = use(S5());
}

class M6 extends RackModule {
  late final s = use(S6());
}

class M7 extends RackModule {
  late final s = use(S7());
}

class M8 extends RackModule {
  late final s = use(S8());
}

class M9 extends RackModule {
  late final s = use(S9());
}

final rackModules = <RackModule>[
  M0(),
  M1(),
  M2(),
  M3(),
  M4(),
  M5(),
  M6(),
  M7(),
  M8(),
  M9(),
];

class RackScreen extends RackWidget<Controller> {
  const RackScreen({super.key});

  @override
  Controller create(Rack rack) => Controller(rack.module<M5>().s);

  @override
  Widget buildContent(BuildContext context, Controller controller) =>
      const SizedBox.shrink();
}

// --- plain Flutter ------------------------------------------------------------

final plainService = S5();

class PlainScreen extends StatefulWidget {
  const PlainScreen({super.key});

  @override
  State<PlainScreen> createState() => _PlainScreenState();
}

class _PlainScreenState extends State<PlainScreen> {
  late final Controller controller;

  @override
  void initState() {
    super.initState();
    controller = Controller(plainService);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// --- provider -----------------------------------------------------------------

final providerServices = <Service>[
  S0(),
  S1(),
  S2(),
  S3(),
  S4(),
  S5(),
  S6(),
  S7(),
  S8(),
  S9(),
];

Widget providerRoot(Widget child) => MultiProvider(
      providers: [
        Provider<S0>.value(value: providerServices[0] as S0),
        Provider<S1>.value(value: providerServices[1] as S1),
        Provider<S2>.value(value: providerServices[2] as S2),
        Provider<S3>.value(value: providerServices[3] as S3),
        Provider<S4>.value(value: providerServices[4] as S4),
        Provider<S5>.value(value: providerServices[5] as S5),
        Provider<S6>.value(value: providerServices[6] as S6),
        Provider<S7>.value(value: providerServices[7] as S7),
        Provider<S8>.value(value: providerServices[8] as S8),
        Provider<S9>.value(value: providerServices[9] as S9),
      ],
      child: child,
    );

/// The usual provider pattern for a screen-scoped controller.
class ProviderScreen extends StatelessWidget {
  const ProviderScreen({super.key});

  @override
  Widget build(BuildContext context) => Provider<Controller>(
        create: (context) => Controller(context.read<S5>()),
        dispose: (_, c) => c.dispose(),
        child: Builder(builder: (context) {
          context.read<Controller>();
          return const SizedBox.shrink();
        }),
      );
}

// --- Harness ----------------------------------------------------------------

enum Impl { plain, rack, provider }

class Harness extends StatefulWidget {
  const Harness({super.key});

  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  Impl impl = Impl.plain;
  bool mounted_ = false;
  int generation = 0;

  void set(void Function() change) => setState(change);

  Widget screen(int i) {
    // New, non-const instances so a rebuild really updates every screen.
    final key = ValueKey(i);
    return switch (impl) {
      Impl.plain => PlainScreen(key: key),
      Impl.rack => RackScreen(key: key),
      Impl.provider => ProviderScreen(key: key),
    };
  }

  @override
  Widget build(BuildContext context) {
    final list = Column(
      key: ValueKey(impl),
      children: [
        if (mounted_)
          for (var i = 0; i < screens; i++) screen(i),
      ],
    );
    final Widget tree = switch (impl) {
      Impl.plain => list,
      Impl.rack => RackProvider(
          key: const ValueKey('rack'),
          modules: rackModules,
          builder: () => list,
        ),
      Impl.provider => providerRoot(list),
    };
    return Directionality(textDirection: TextDirection.ltr, child: tree);
  }
}

final harnessKey = GlobalKey<HarnessState>();

/// Applies [change] and runs the resulting build synchronously; returns µs.
double timeBuild(void Function() change) {
  final binding = WidgetsBinding.instance;
  final sw = Stopwatch()..start();
  harnessKey.currentState!.set(change);
  binding.buildOwner!.buildScope(binding.rootElement!);
  binding.buildOwner!.finalizeTree();
  sw.stop();
  return sw.elapsedMicroseconds.toDouble();
}

double median(List<double> xs) {
  final s = [...xs]..sort();
  return s.length.isOdd
      ? s[s.length ~/ 2]
      : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Harness(key: harnessKey));
  await WidgetsBinding.instance.endOfFrame;

  final results = <String, Map<String, double>>{};
  for (final impl in Impl.values) {
    final h = harnessKey.currentState!;
    h.set(() => h.impl = impl);
    await WidgetsBinding.instance.endOfFrame;
    // Let RackProvider finish its (empty) async init.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;

    final mount = <double>[], rebuild = <double>[], unmount = <double>[];
    for (var r = 0; r < warmup + rounds; r++) {
      final m = timeBuild(() => h.mounted_ = true);
      final b = timeBuild(() => h.generation++);
      final u = timeBuild(() => h.mounted_ = false);
      await WidgetsBinding.instance.endOfFrame;
      if (r >= warmup) {
        mount.add(m);
        rebuild.add(b);
        unmount.add(u);
      }
    }
    results[impl.name] = {
      'mount_us_per_screen': median(mount) / screens,
      'rebuild_us_per_screen': median(rebuild) / screens,
      'unmount_us_per_screen': median(unmount) / screens,
    };
  }

  final json = const JsonEncoder.withIndent('  ').convert({
    'screens': screens,
    'rounds': rounds,
    'modules': moduleCount,
    'results': results,
  });
  stdout.writeln(json);
  exit(0);
}
