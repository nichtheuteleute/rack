import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../module/disposable.dart';
import '../module/rack_injector.dart';

class RackWidget<C> extends StatelessWidget {
  final C Function(RackInjector injector) create;
  final Widget Function(BuildContext context, C controller) builder;

  const RackWidget({super.key, required this.create, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Provider<C>(
      create: (context) => create(RackInjector(context)),
      dispose: (_, controller) {
        if (controller is Disposable) controller.dispose();
      },
      child: Builder(
        builder: (context) => builder(context, context.read<C>()),
      ),
    );
  }
}
