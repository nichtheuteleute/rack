import 'package:flutter_test/flutter_test.dart';
import 'package:morph_md_rack/rack.dart';

class _Tracked implements Disposable {
  _Tracked(this.log, this.tag);
  final List<String> log;
  final String tag;

  @override
  void dispose() => log.add(tag);
}

class _Plain {}

class _MultiModule extends RackModule {
  _MultiModule(this.log);
  final List<String> log;

  late final a = use(_Tracked(log, 'a'));
  late final b = use(_Tracked(log, 'b'));
}

class _PlainModule extends RackModule {
  late final value = use(_Plain());
}

class _CoreModule extends RackModule {
  late final settings = use(_Tracked(<String>[], 'core'));
}

class _DependentModule extends RackModule {
  _DependentModule(this.core);
  final _CoreModule core;
}

void main() {
  group('RackModule', () {
    test('a dep returns the same instance every time it is read', () {
      final module = _MultiModule(<String>[]);

      expect(identical(module.a, module.a), isTrue);
    });

    test('disposes its deps in reverse creation order', () {
      final log = <String>[];
      final module = _MultiModule(log);

      expect(module.a.tag, 'a'); // creates a
      expect(module.b.tag, 'b'); // creates b
      expect(log, isEmpty);

      module.dispose();

      expect(log, ['b', 'a']);
    });

    test('a dep that is never read is never created or disposed', () {
      final log = <String>[];
      final module = _MultiModule(log);

      expect(module.a.tag, 'a'); // only a is created

      module.dispose();

      expect(log, ['a']);
    });

    test('a non-Disposable dep is left untouched on dispose', () {
      final module = _PlainModule();

      expect(module.value, isNotNull);
      expect(module.dispose, returnsNormally);
    });

    test('a module reads its typed dependency module directly', () {
      final core = _CoreModule();
      final dependent = _DependentModule(core);

      expect(dependent.core, same(core));
      expect(dependent.core.settings.tag, 'core');
    });
  });
}
