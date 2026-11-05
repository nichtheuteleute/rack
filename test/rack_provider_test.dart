import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rack/rack.dart';

class _ValueModule extends RackModule {
  _ValueModule(this.value) : super(dependsOn: const []);
  final String value;
}

class _SlowModule extends RackModule {
  _SlowModule(this._completer) : super(dependsOn: const []);
  final Completer<void> _completer;

  @override
  Future<void> init() => _completer.future;
}

class _ThrowingModule extends RackModule {
  _ThrowingModule() : super(dependsOn: const []);

  @override
  Future<void> init() async => throw Exception('boom');
}

class _DisposeOrderModule extends RackModule {
  _DisposeOrderModule(this._log, this.tag) : super(dependsOn: const []);
  final List<String> _log;
  final String tag;

  @override
  void dispose() {
    _log.add(tag);
    super.dispose();
  }
}

/// Records when its init starts; finishes when [finish] is called. The type
/// argument only gives each instance its own module type.
class _TrackedModule<T> extends RackModule {
  _TrackedModule(this.name, this.started, {List<RackModule> deps = const []})
      : super(dependsOn: deps);
  final String name;
  final List<String> started;
  final _completer = Completer<void>();

  void finish() => _completer.complete();

  @override
  Future<void> init() {
    started.add(name);
    return _completer.future;
  }
}

class _FailingModule extends RackModule {
  _FailingModule() : super(dependsOn: const []);

  @override
  Future<void> init() async => throw Exception('boom');
}

/// Cycles cannot be built through constructors; a subclass overriding
/// [RackModule.dependsOn] could still create one.
class _CycleA extends RackModule {
  _CycleA() : super(dependsOn: const []);
  late RackModule other;
  @override
  List<RackModule> get dependsOn => [other];
}

class _CycleB extends RackModule {
  _CycleB(this.other) : super(dependsOn: const []);
  final RackModule other;
  @override
  List<RackModule> get dependsOn => [other];
}

class _A {}

class _B {}

class _C {}

class _Child {}

class _Dependent {}

class _Files {}

class _Other {}

class _Parent {}

class _Settings {}

class _Notes {}

class _Storage {}

/// Logs init and dispose.
class _LoggingModule<T> extends RackModule {
  _LoggingModule(this.name, this.log, List<RackModule> deps)
      : super(dependsOn: deps);
  final String name;
  final List<String> log;

  @override
  Future<void> init() async => log.add('init $name');

  @override
  void dispose() {
    log.add('dispose $name');
    super.dispose();
  }
}

class _LookupWidget extends StatelessWidget {
  const _LookupWidget(this.lookup);
  final void Function(Rack rack) lookup;

  @override
  Widget build(BuildContext context) {
    lookup(Rack(context));
    return const SizedBox.shrink();
  }
}

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('RackProvider', () {
    testWidgets('shows the loading widget while a module is initializing',
        (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_SlowModule(completer)],
            builder: () => const Text('ready'),
            loading: const Text('loading'),
          ),
        ),
      );

      expect(find.text('loading'), findsOneWidget);
      expect(find.text('ready'), findsNothing);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('loading'), findsNothing);
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('shows the builder content once modules are initialized',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ValueModule('hello')],
            builder: () => const Text('ready'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets(
        'shows an ErrorWidget when a module fails to init and no errorBuilder is set',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ThrowingModule()],
            builder: () => const Text('ready'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsOneWidget);
    });

    testWidgets(
        'calls the custom errorBuilder with the error when a module fails to init',
        (tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ThrowingModule()],
            builder: () => const SizedBox.shrink(),
            errorBuilder: (e) {
              capturedError = e;
              return const Text('error shown');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedError, isNotNull);
      expect(find.text('error shown'), findsOneWidget);
    });

    testWidgets('the init error names the module that failed', (tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ThrowingModule()],
            builder: () => const SizedBox.shrink(),
            errorBuilder: (e) {
              capturedError = e;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedError.toString(), contains('_ThrowingModule'));
    });

    testWidgets('disposes modules in reverse list order on unmount',
        (tester) async {
      final log = <String>[];

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [
              _DisposeOrderModule(log, 'first'),
              _DisposeOrderModule(log, 'second'),
            ],
            builder: () => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      expect(log, ['second', 'first']);
    });

    testWidgets('keeps its original modules when rebuilt with new instances',
        (tester) async {
      final log = <String>[];
      late String value;

      Widget provider(String tag) => _wrap(
            RackProvider(
              modules: [_DisposeOrderModule(log, tag)],
              builder: () => Builder(
                builder: (ctx) {
                  final module =
                      RackInherited.of(ctx).module<_DisposeOrderModule>();
                  value = module.tag;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

      await tester.pumpWidget(provider('original'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(provider('rebuilt'));
      await tester.pumpAndSettle();

      expect(value, 'original');

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      expect(log, ['original']);
    });

    testWidgets(
        'a widget in a nested provider can read a module from the parent',
        (tester) async {
      late String value;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ValueModule('from-parent')],
            builder: () => RackProvider(
              modules: const [],
              builder: () => Builder(
                builder: (ctx) {
                  value = RackInherited.of(ctx).module<_ValueModule>().value;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(value, 'from-parent');
    });

    testWidgets('a nested module shadows a parent module of the same type',
        (tester) async {
      late String value;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ValueModule('parent')],
            builder: () => RackProvider(
              modules: [_ValueModule('child')],
              builder: () => Builder(
                builder: (ctx) {
                  value = RackInherited.of(ctx).module<_ValueModule>().value;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(value, 'child');
    });
  });

  group('RackInherited', () {
    test('module throws naming the missing type', () {
      const inherited = RackInherited(
        modules: <Type, RackModule>{},
        child: SizedBox.shrink(),
      );

      expect(
        () => inherited.module<_ValueModule>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('_ValueModule'),
          ),
        ),
      );
    });

    test('moduleOrNull returns null for an unregistered module', () {
      const inherited = RackInherited(
        modules: <Type, RackModule>{},
        child: SizedBox.shrink(),
      );

      expect(inherited.moduleOrNull<_ValueModule>(), isNull);
    });

    testWidgets('of asserts when no provider is in the tree', (tester) async {
      BuildContext? capturedCtx;

      await tester.pumpWidget(
        _wrap(
          Builder(builder: (ctx) {
            capturedCtx = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );

      expect(
        () => RackInherited.of(capturedCtx!),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('No RackProvider found'),
          ),
        ),
      );
    });
  });

  group('RackProvider init order', () {
    Widget provider(List<RackModule> modules,
            {void Function(Object)? onError}) =>
        _wrap(RackProvider(
          modules: modules,
          builder: () => const Text('ready'),
          errorBuilder: (e) {
            onError?.call(e);
            return const Text('error');
          },
        ));

    testWidgets('modules with dependsOn: [] initialize in parallel',
        (tester) async {
      final started = <String>[];
      final a = _TrackedModule<_A>('a', started, deps: const []);
      final b = _TrackedModule<_B>('b', started, deps: const []);
      final c = _TrackedModule<_C>('c', started, deps: const []);
      await tester.pumpWidget(provider([a, b, c]));
      await tester.pump();
      expect(started, ['a', 'b', 'c']);

      c.finish();
      b.finish();
      await tester.pump();
      expect(find.text('ready'), findsNothing);
      a.finish();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('a module waits for the modules it depends on', (tester) async {
      final started = <String>[];
      final settings =
          _TrackedModule<_Settings>('settings', started, deps: const []);
      final other = _TrackedModule<_Other>('other', started, deps: const []);
      final files = _TrackedModule<_Files>('files', started, deps: [settings]);
      // Listed before its dependency on purpose: order does not matter
      // once dependencies are declared.
      await tester.pumpWidget(provider([files, settings, other]));
      await tester.pump();
      expect(started, unorderedEquals(['settings', 'other']));

      other.finish();
      await tester.pump();
      expect(started, isNot(contains('files')));

      settings.finish();
      await tester.pump();
      expect(started.last, 'files');

      files.finish();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('a dependency provided by a parent provider is reused',
        (tester) async {
      final started = <String>[];
      final parentModule =
          _TrackedModule<_Parent>('parent', started, deps: const []);
      final child =
          _TrackedModule<_Child>('child', started, deps: [parentModule]);
      parentModule.finish();
      await tester.pumpWidget(_wrap(RackProvider(
        modules: [parentModule],
        builder: () => RackProvider(
          modules: [child],
          builder: () => const Text('ready'),
        ),
      )));
      await tester.pump();
      await tester.pump();
      expect(started, ['parent', 'child']);
      child.finish();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(started, ['parent', 'child']);
    });

    testWidgets('a failing dependency stops its dependents and is reported',
        (tester) async {
      final started = <String>[];
      final failing = _FailingModule();
      final dependent =
          _TrackedModule<_Dependent>('dependent', started, deps: [failing]);
      Object? error;
      await tester.pumpWidget(
          provider([failing, dependent], onError: (e) => error = e));
      await tester.pumpAndSettle();

      expect(started, isEmpty);
      expect(find.text('error'), findsOneWidget);
      expect(error.toString(), contains('_FailingModule.init() failed'));
    });

    testWidgets('a dependency cycle is reported as an error', (tester) async {
      final a = _CycleA();
      final b = _CycleB(a);
      a.other = b;
      Object? error;
      await tester.pumpWidget(provider([a, b], onError: (e) => error = e));
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
      expect(error.toString(), contains('cycle'));
      expect(error.toString(), contains('_CycleA -> _CycleB -> _CycleA'));
    });
  });

  group('RackProvider dependency registration', () {
    testWidgets(
        'an unlisted dependency is registered, initialized first, '
        'provided and disposed', (tester) async {
      final log = <String>[];
      final settings = _LoggingModule<_Settings>('settings', log, const []);
      final notes = _LoggingModule<_Notes>('notes', log, [settings]);

      late _LoggingModule<_Settings> looked;
      await tester.pumpWidget(_wrap(RackProvider(
        modules: [notes], // settings is not listed
        builder: () => _LookupWidget(
          (rack) => looked = rack.module<_LoggingModule<_Settings>>(),
        ),
      )));
      await tester.pumpAndSettle();

      expect(log, ['init settings', 'init notes']);
      expect(looked, same(settings));

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      expect(log, [
        'init settings',
        'init notes',
        'dispose notes',
        'dispose settings',
      ]);
    });

    testWidgets('dependencies are registered transitively', (tester) async {
      final log = <String>[];
      final storage = _LoggingModule<_Storage>('storage', log, const []);
      final settings = _LoggingModule<_Settings>('settings', log, [storage]);
      final notes = _LoggingModule<_Notes>('notes', log, [settings]);

      await tester.pumpWidget(_wrap(RackProvider(
        modules: [notes],
        builder: () => const Text('ready'),
      )));
      await tester.pumpAndSettle();

      expect(log, ['init storage', 'init settings', 'init notes']);
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('two instances of one module type are reported',
        (tester) async {
      final log = <String>[];
      final settingsA = _LoggingModule<_Settings>('a', log, const []);
      final settingsB = _LoggingModule<_Settings>('b', log, const []);
      final notes = _LoggingModule<_Notes>('notes', log, [settingsB]);
      Object? error;

      await tester.pumpWidget(_wrap(RackProvider(
        modules: [settingsA, notes],
        builder: () => const Text('ready'),
        errorBuilder: (e) {
          error = e;
          return const Text('error');
        },
      )));
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
      expect(error.toString(), contains('Two different'));
      expect(log, isEmpty);
    });
  });
}
