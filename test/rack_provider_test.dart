import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_md_rack/rack.dart';

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

class _DisposeOrderModule extends RackModule {
  _DisposeOrderModule(this._log, this._tag);
  final List<String> _log;
  final String _tag;

  @override
  void dispose() {
    _log.add(_tag);
    super.dispose();
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

    testWidgets('a widget in a nested provider can read a module from the parent',
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
}
