import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _CountingWidget extends RackWidget<Object> {
  final void Function() onCreate;

  const _CountingWidget({required this.onCreate});

  @override
  Object create(Rack rack) {
    onCreate();
    return Object();
  }

  @override
  Widget buildContent(BuildContext context, Object controller) =>
      const SizedBox.shrink();
}

class _DisposableController implements Disposable {
  final void Function() onDispose;
  _DisposableController(this.onDispose);

  @override
  void dispose() => onDispose();
}

class _DisposableWidget extends RackWidget<_DisposableController> {
  final void Function() onDispose;

  const _DisposableWidget({required this.onDispose});

  @override
  _DisposableController create(Rack rack) => _DisposableController(onDispose);

  @override
  Widget buildContent(BuildContext context, _DisposableController controller) =>
      const SizedBox.shrink();
}

class _PlainController {}

class _PlainWidget extends RackWidget<_PlainController> {
  const _PlainWidget();

  @override
  _PlainController create(Rack rack) => _PlainController();

  @override
  Widget buildContent(BuildContext context, _PlainController controller) =>
      const SizedBox.shrink();
}

class _ServiceController {
  final String value;
  _ServiceController(this.value);
}

class _ServiceWidget extends RackWidget<_ServiceController> {
  const _ServiceWidget();

  @override
  _ServiceController create(Rack rack) =>
      _ServiceController(rack.module<_ValueModule>().value);

  @override
  Widget buildContent(BuildContext context, _ServiceController controller) =>
      Text(controller.value);
}

class _ValueModule extends RackModule {
  _ValueModule(this.value);
  final String value;
}

class _CounterController {
  final count = signal(0);
}

class _CounterWidget extends RackWidget<_CounterController> {
  const _CounterWidget({required this.onCreate});
  final void Function(_CounterController) onCreate;

  @override
  _CounterController create(Rack rack) {
    final controller = _CounterController();
    onCreate(controller);
    return controller;
  }

  @override
  Widget buildContent(BuildContext context, _CounterController controller) =>
      Text('count: ${controller.count.value}');
}

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('RackWidget', () {
    testWidgets('create is called exactly once during initial build',
        (tester) async {
      var count = 0;

      await tester.pumpWidget(
        _wrap(_CountingWidget(onCreate: () => count++)),
      );

      expect(count, 1);
    });

    testWidgets('create is not called again on subsequent frames',
        (tester) async {
      var count = 0;

      await tester.pumpWidget(
        _wrap(_CountingWidget(onCreate: () => count++)),
      );
      await tester.pump();

      expect(count, 1);
    });

    testWidgets('Disposable controller is disposed when widget unmounts',
        (tester) async {
      var disposed = false;

      await tester.pumpWidget(
        _wrap(_DisposableWidget(onDispose: () => disposed = true)),
      );
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      expect(disposed, isTrue);
    });

    testWidgets('non-Disposable controller does not cause errors on unmount',
        (tester) async {
      await tester.pumpWidget(_wrap(const _PlainWidget()));
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'controller reads a module from Rack and shows it in buildContent',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          RackProvider(
            modules: [_ValueModule('rack-value')],
            builder: () => const _ServiceWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('rack-value'), findsOneWidget);
    });

    testWidgets('rebuilds when a signal read in buildContent changes',
        (tester) async {
      late _CounterController controller;
      await tester.pumpWidget(
        _wrap(_CounterWidget(onCreate: (c) => controller = c)),
      );
      expect(find.text('count: 0'), findsOneWidget);

      controller.count.value = 1;
      await tester.pump();

      expect(find.text('count: 1'), findsOneWidget);
    });
  });
}
