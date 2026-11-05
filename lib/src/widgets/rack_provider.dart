import 'package:flutter/widgets.dart';
import '../core/rack_inherited.dart';
import '../module/rack_module.dart';

/// Composition root: initializes [modules] and provides them to the
/// subtree built by [builder].
///
/// Each module's `init()` runs once its [RackModule.dependsOn] modules have
/// finished — by default that is every module listed before it, so modules
/// initialize one after another in list order. Modules that declare their
/// dependencies explicitly initialize in parallel where possible. Until all
/// of them have completed, [loading] is shown; if one throws or the declared
/// dependencies form a cycle, [errorBuilder] is shown. The modules are
/// disposed in reverse order when the provider unmounts.
///
/// Modules named in a module's [RackModule.dependsOn] are registered
/// automatically if they are neither in [modules] nor provided by a parent
/// provider — forgetting to list a dependency cannot leave it uninitialized.
/// Two different instances of the same module type are reported as an error.
///
/// Providers can be nested: a nested provider sees its parent's modules, and
/// its own modules replace parent modules of the same type.
class RackProvider extends StatefulWidget {
  /// The modules to provide, already instantiated. A module that depends on
  /// another takes it as a constructor argument and is listed after it — or
  /// names it in [RackModule.dependsOn], then it is registered automatically
  /// and need not be listed.
  ///
  /// Read once when the provider mounts: the provider owns these instances
  /// and disposes them on unmount. Modules passed on a later rebuild are
  /// ignored.
  final List<RackModule> modules;

  /// Builds the subtree once all modules are initialized.
  final Widget Function() builder;

  /// Shown while modules are initializing. Defaults to an empty widget.
  final Widget loading;

  /// Shown when a module's init throws. Defaults to a plain error widget.
  final Widget Function(Object error)? errorBuilder;

  /// Creates a provider for [modules].
  const RackProvider({
    super.key,
    required this.modules,
    required this.builder,
    this.loading = const SizedBox.shrink(),
    this.errorBuilder,
  });

  @override
  State<RackProvider> createState() => _RackProviderState();
}

class _RackProviderState extends State<RackProvider> {
  /// The listed modules plus the dependencies registered automatically.
  /// Read once when the provider mounts; the provider owns all of them.
  late List<RackModule> _modules = List.unmodifiable(widget.modules);
  bool _initStarted = false;
  bool _initialized = false;
  Object? _initError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted) {
      _initStarted = true;
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      final parent = context.getInheritedWidgetOfExactType<RackInherited>();
      _modules = List.unmodifiable(
        _withDependencies(parent?.modules.values.toSet() ?? const {}),
      );
      _checkOneInstancePerType();
      final order = _initOrder();
      final done = <RackModule, Future<void>>{};
      for (final module in order) {
        final deps = _dependenciesOf(module);
        done[module] = Future.wait([for (final d in deps) done[d]!])
            .then((_) => _init(module));
      }
      await Future.wait(done.values);
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e);
    }
  }

  Future<void> _init(RackModule module) async {
    if (!mounted) return;
    try {
      await module.init();
    } catch (e) {
      throw StateError('${module.runtimeType}.init() failed: $e');
    }
  }

  /// The listed modules plus every module they declare in
  /// [RackModule.dependsOn] (transitively) that is neither listed nor
  /// provided by a parent provider. A dependency is placed right before the
  /// first module that needs it.
  List<RackModule> _withDependencies(Set<RackModule> fromParent) {
    final listed = widget.modules.toSet();
    final result = <RackModule>[];
    final visiting = <RackModule>{};
    void add(RackModule module) {
      if (result.contains(module) || !visiting.add(module)) return;
      for (final dep in module.dependsOn ?? const <RackModule>[]) {
        if (!listed.contains(dep) && !fromParent.contains(dep)) add(dep);
      }
      visiting.remove(module);
      result.add(module);
    }

    widget.modules.forEach(add);
    return result;
  }

  /// Two different instances of one module type would make lookups by type
  /// ambiguous — usually a module was created twice by mistake.
  void _checkOneInstancePerType() {
    final byType = <Type, RackModule>{};
    for (final module in _modules) {
      if (byType.containsKey(module.runtimeType)) {
        throw StateError(
          'Two different ${module.runtimeType} instances in one RackProvider. '
          'Create the module once and pass the same instance to every module '
          'that depends on it.',
        );
      }
      byType[module.runtimeType] = module;
    }
  }

  /// The modules of this provider that [module] waits for.
  List<RackModule> _dependenciesOf(RackModule module) {
    final declared = module.dependsOn;
    if (declared == null) {
      return _modules.sublist(0, _modules.indexOf(module));
    }
    return [
      for (final dep in declared)
        if (_modules.contains(dep)) dep,
    ];
  }

  /// [_modules] sorted so that every module comes after its dependencies.
  /// Throws a [StateError] if the dependencies form a cycle.
  List<RackModule> _initOrder() {
    final order = <RackModule>[];
    final visiting = <RackModule>[];
    void visit(RackModule module) {
      if (order.contains(module)) return;
      if (visiting.contains(module)) {
        final cycle = [
          ...visiting.sublist(visiting.indexOf(module)),
          module,
        ].map((m) => m.runtimeType).join(' -> ');
        throw StateError('Module dependencies form a cycle: $cycle');
      }
      visiting.add(module);
      _dependenciesOf(module).forEach(visit);
      visiting.removeLast();
      order.add(module);
    }

    _modules.forEach(visit);
    return order;
  }

  @override
  void dispose() {
    for (final module in _modules.reversed) {
      module.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return widget.errorBuilder?.call(_initError!) ?? ErrorWidget(_initError!);
    }
    if (!_initialized) return widget.loading;

    final parent = context.getInheritedWidgetOfExactType<RackInherited>();
    final modules = <Type, RackModule>{
      if (parent != null) ...parent.modules,
      for (final module in _modules) module.runtimeType: module,
    };
    return RackInherited(
      modules: modules,
      child: widget.builder(),
    );
  }
}
