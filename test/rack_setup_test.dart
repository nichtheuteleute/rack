import 'package:flutter_test/flutter_test.dart';
import 'package:morph_md_rack/rack.dart';

class _Tracked implements Disposable {
  bool disposed = false;

  @override
  void dispose() => disposed = true;
}

void main() {
  group('RackSetup', () {
    test('read returns registered service', () {
      final services = <Type, Object>{};
      final rack = RackSetup(services, []);
      rack.register<String>('hello');

      expect(rack.read<String>(), 'hello');
    });

    test('read returns service from parent when not in local services', () {
      final parent = <Type, Object>{int: 42};
      final rack = RackSetup(<Type, Object>{}, [], parent);

      expect(rack.read<int>(), 42);
    });

    test('local service shadows parent service of same type', () {
      final parent = <Type, Object>{String: 'parent'};
      final rack = RackSetup(<Type, Object>{}, [], parent);
      rack.register<String>('child');

      expect(rack.read<String>(), 'child');
    });

    test('read throws AssertionError for unregistered type with informative message', () {
      final rack = RackSetup(<Type, Object>{}, []);

      expect(
        () => rack.read<double>(),
        throwsA(
          isA<AssertionError>()
              .having((e) => e.message, 'message', contains('double'))
              .having(
                (e) => e.message,
                'message',
                contains('check module order in RackProvider'),
              ),
        ),
      );
    });

    test('auto-disposes Disposable instances', () {
      final disposers = <void Function()>[];
      final rack = RackSetup(<Type, Object>{}, disposers);
      final tracked = _Tracked();
      rack.register<_Tracked>(tracked);

      expect(disposers.length, 1);
      disposers.first();
      expect(tracked.disposed, isTrue);
    });

    test('calls explicit dispose callback and does not call Disposable.dispose separately', () {
      final disposers = <void Function()>[];
      final rack = RackSetup(<Type, Object>{}, disposers);
      final tracked = _Tracked();
      var callbackCalled = false;
      rack.register<_Tracked>(tracked, dispose: (_) => callbackCalled = true);

      expect(disposers.length, 1);
      disposers.first();
      expect(callbackCalled, isTrue);
      expect(tracked.disposed, isFalse);
    });

    test('does not add a disposer for plain instances without callback', () {
      final disposers = <void Function()>[];
      final rack = RackSetup(<Type, Object>{}, disposers);
      rack.register<String>('plain');

      expect(disposers, isEmpty);
    });
  });

  group('RackModule.instance', () {
    test('registers value correctly', () async {
      final services = <Type, Object>{};
      final rack = RackSetup(services, []);
      final module = RackModule.instance<String>('value');
      await module.setup(rack);

      expect(rack.read<String>(), 'value');
    });

    test('Disposable value gets auto-disposed', () async {
      final disposers = <void Function()>[];
      final rack = RackSetup(<Type, Object>{}, disposers);
      final tracked = _Tracked();
      final module = RackModule.instance<_Tracked>(tracked);
      await module.setup(rack);

      expect(disposers.length, 1);
      disposers.first();
      expect(tracked.disposed, isTrue);
    });
  });
}
