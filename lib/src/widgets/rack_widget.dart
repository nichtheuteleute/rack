import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../module/disposable.dart';
import '../module/rack.dart';

/// Base class for a widget that owns a controller of type [C].
///
/// The controller is created once by [create] when the widget mounts and is
/// kept across rebuilds. If it implements [Disposable], it is disposed when
/// the widget unmounts.
///
/// [buildContent] runs inside a signals `SignalBuilder`: reading a signal there
/// rebuilds the widget when the signal changes.
abstract class RackWidget<C extends Object> extends StatefulWidget {
  /// Creates a widget that owns a controller of type [C].
  const RackWidget({super.key});

  /// Creates the controller. Called once, when the widget mounts.
  ///
  /// Use [rack] to look up the modules the controller needs.
  C create(Rack rack);

  /// Builds the widget's UI from [controller].
  ///
  /// Signals read here are tracked and trigger a rebuild when they change.
  Widget buildContent(BuildContext context, C controller);

  @override
  State<RackWidget<C>> createState() => _RackWidgetState<C>();
}

class _RackWidgetState<C extends Object> extends State<RackWidget<C>> {
  C? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= widget.create(Rack(context));
  }

  @override
  void dispose() {
    final c = _controller;
    if (c is Disposable) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) => widget.buildContent(context, _controller!),
    );
  }
}
