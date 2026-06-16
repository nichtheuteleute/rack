import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_md_rack/rack.dart';

class _SlowModule extends RackModule {
  final Completer<void> _completer;
  const _SlowModule(this._completer);

  @override
  Future<void> setup(RackSetup rack) => _completer.future;
}

class _ThrowingModule extends RackModule {
  const _ThrowingModule();

  @override
  Future<void> setup(RackSetup rack) async => throw Exception('boom');
}

class _StringModule extends RackModule {
  final String _value;
  const _StringModule(this._value);

  @override
  Future<void> setup(RackSetup rack) async =>
      rack.register<String>(_value);
}

class _ServiceA implements Disposable {
  final List<String> log;
  _ServiceA(this.log);

  @override
  void dispose() => log.add('A');
}

class _ServiceB implements Disposable {
  final List<String> log;
  _ServiceB(this.log);

  @override
  void dispose() => log.add('B');
}

class _ABModule extends RackModule {
  final List<String> _log;
  const _ABModule(this._log);

  @override
  Future<void> setup(RackSetup rack) async {
    rack.register<_ServiceA>(_ServiceA(_log));
    rack.register<_ServiceB>(_ServiceB(_log));
  }
}

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('RackProvider', () {
    testWidgets('shows loading widget while async module is initializing',
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

    testWidgets('shows builder content after synchronous module completes',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _StringModule('hello')],
            builder: () => const Text('ready'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('shows ErrorWidget when a module throws and no errorBuilder set',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _ThrowingModule()],
            builder: () => const Text('ready'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsOneWidget);
    });

    testWidgets('custom errorBuilder is called with the error when module throws',
        (tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _ThrowingModule()],
            builder: () => const Text('ready'),
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

    testWidgets('error message contains the module runtime type name',
        (tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _ThrowingModule()],
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

    testWidgets(
        'error message contains services registered before the failure',
        (tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _StringModule('first'), const _ThrowingModule()],
            builder: () => const SizedBox.shrink(),
            errorBuilder: (e) {
              capturedError = e;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedError.toString(), contains('String'));
    });

    testWidgets('services disposed in reverse registration order on unmount',
        (tester) async {
      final log = <String>[];

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ABModule(log)],
            builder: () => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      expect(log, ['B', 'A']);
    });

    testWidgets(
        'nested provider: widget inside nested provider can read parent services',
        (tester) async {
      late String value;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _StringModule('from-parent')],
            builder: () => RackProvider(
              modules: const [],
              builder: () => Builder(
                builder: (ctx) {
                  value = RackInherited.of(ctx).get<String>();
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

    testWidgets(
        'nested provider: child service overrides parent service of same type',
        (tester) async {
      late String value;

      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [const _StringModule('parent')],
            builder: () => RackProvider(
              modules: [const _StringModule('child')],
              builder: () => Builder(
                builder: (ctx) {
                  value = RackInherited.of(ctx).get<String>();
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
    test('get asserts with message containing missing type name', () {
      final inherited = RackInherited(
        services: const {},
        child: const SizedBox.shrink(),
      );

      expect(
        () => inherited.get<String>(),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('String'),
          ),
        ),
      );
    });

    testWidgets('of asserts with No RackProvider found when no provider in tree',
        (tester) async {
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
}
