import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rack/rack.dart';

class _ValueModule extends RackModule {
  _ValueModule(this.value);
  final String value;
}

class _SlowModule extends RackModule {
  _SlowModule(this._completer);
  final Completer<void> _completer;

  @override
  Future<void> init() => _completer.future;
}

class _ThrowingModule extends RackModule {
  @override
  Future<void> init() async => throw Exception('boom');
}

/// The type argument only gives each instance its own module type.
class _DisposeOrderModule<T> extends RackModule {
  _DisposeOrderModule(this._log, this.tag);
  final List<String> _log;
  final String tag;

  @override
  void dispose() {
    _log.add(tag);
    super.dispose();
  }
}

class _A {}

class _B {}

/// Logs when its init starts; finishes when [finish] is called.
class _StepModule<T> extends RackModule {
  _StepModule(this.name, this.log);
  final String name;
  final List<String> log;
  final _completer = Completer<void>();

  void finish() => _completer.complete();

  @override
  Future<void> init() {
    log.add(name);
    return _completer.future;
  }
}

class _Store {}

class _SettingsModule extends RackModule {
  late final store = use(_Store());
  bool loaded = false;

  @override
  Future<void> init() async => loaded = true;
}

/// Reads its dependency's store during init, like a real feature module.
class _NotesModule extends RackModule {
  _NotesModule(this.settings);
  final _SettingsModule settings;

  @override
  Future<void> init() async {
    settings.store;
    if (!settings.loaded) throw StateError('settings not loaded yet');
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

    testWidgets('disposes modules in reverse creation order on unmount',
        (tester) async {
      final log = <String>[];
      final first = _DisposeOrderModule<_A>(log, 'first');
      final second = _DisposeOrderModule<_B>(log, 'second');

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [second, first], // list order does not matter
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
    testWidgets('initializes one module after another in creation order',
        (tester) async {
      final log = <String>[];
      final settings = _StepModule<_A>('settings', log);
      final notes = _StepModule<_B>('notes', log);

      await tester.pumpWidget(_wrap(RackProvider(
        modules: [notes, settings], // listed in the "wrong" order
        builder: () => const Text('ready'),
      )));
      await tester.pump();
      expect(log, ['settings']);

      settings.finish();
      await tester.pump();
      expect(log, ['settings', 'notes']);
      expect(find.text('ready'), findsNothing);

      notes.finish();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('a dependency is always initialized before its dependent',
        (tester) async {
      Object? error;
      final notes = _NotesModule(_SettingsModule()); // created inline
      final settings = notes.settings;

      await tester.pumpWidget(_wrap(RackProvider(
        modules: [notes, settings],
        builder: () => const Text('ready'),
        errorBuilder: (e) {
          error = e;
          return const Text('error');
        },
      )));
      await tester.pumpAndSettle();

      expect(error, isNull);
      expect(find.text('ready'), findsOneWidget);
    });
  });

  group('RackProvider wiring checks', () {
    testWidgets('a used module that is not provided is reported',
        (tester) async {
      Object? error;
      final settings = _SettingsModule();
      final notes = _NotesModule(settings);

      await tester.pumpWidget(_wrap(RackProvider(
        modules: [notes], // settings forgotten
        builder: () => const Text('ready'),
        errorBuilder: (e) {
          error = e;
          return const Text('error');
        },
      )));
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
      expect(error.toString(), contains('_SettingsModule is used'));
      expect(error.toString(), contains('Add it to RackProvider.modules'));
    });

    testWidgets('a module provided by a parent provider can be used',
        (tester) async {
      final settings = _SettingsModule();
      final notes = _NotesModule(settings);

      await tester.pumpWidget(_wrap(RackProvider(
        modules: [settings],
        builder: () => RackProvider(
          modules: [notes],
          builder: () => const Text('ready'),
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('a module can be used without any provider, e.g. in tests',
        (tester) async {
      expect(_SettingsModule().store, isA<_Store>());
    });

    testWidgets('two instances of one module type are reported',
        (tester) async {
      Object? error;
      await tester.pumpWidget(_wrap(RackProvider(
        modules: [_SettingsModule(), _SettingsModule()],
        builder: () => const Text('ready'),
        errorBuilder: (e) {
          error = e;
          return const Text('error');
        },
      )));
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
      expect(error.toString(), contains('Two different _SettingsModule'));
    });

    testWidgets('a module listed in two providers is reported', (tester) async {
      Object? error;
      final settings = _SettingsModule();
      await tester.pumpWidget(_wrap(RackProvider(
        modules: [settings],
        builder: () => RackProvider(
          modules: [settings],
          builder: () => const Text('ready'),
          errorBuilder: (e) {
            error = e;
            return const Text('error');
          },
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
      expect(error.toString(), contains('already provided'));
    });

    testWidgets('a lookup finds the module after the wiring checks',
        (tester) async {
      final settings = _SettingsModule();
      late _SettingsModule found;
      await tester.pumpWidget(_wrap(RackProvider(
        modules: [settings],
        builder: () =>
            _LookupWidget((rack) => found = rack.module<_SettingsModule>()),
      )));
      await tester.pumpAndSettle();
      expect(found, same(settings));
    });
  });
}
