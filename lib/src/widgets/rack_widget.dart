import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../module/disposable.dart';
import '../module/rack_injector.dart';

abstract class RackWidget<C extends Object> extends StatefulWidget {
  const RackWidget({super.key});

  C create(RackInjector injector);
  Widget buildContent(BuildContext context, C controller);

  @override
  State<RackWidget<C>> createState() => _RackWidgetState<C>();
}

class _RackWidgetState<C extends Object> extends State<RackWidget<C>> {
  C? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= widget.create(RackInjector(context));
  }

  @override
  void dispose() {
    final c = _controller;
    if (c is Disposable) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((ctx) => widget.buildContent(ctx, _controller!));
  }
}
