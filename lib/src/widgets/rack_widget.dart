import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../module/disposable.dart';
import '../module/rack_injector.dart';

abstract class RackWidget<C> extends StatelessWidget {
  abstract C Function(RackInjector injector) create;
  abstract Widget Function(BuildContext context, C controller) builder;

  RackWidget({super.key});



  @override
  Widget build(BuildContext context) {
    return Provider<C>(
      create: (context) => create(RackInjector(context)),
      dispose: (_, controller) {
        if (controller is Disposable) {
          controller.dispose();
        }
      },
      child: Builder(
        builder: (context) {
          final controller = context.read<C>();
          return builder(context, controller);
        },
      ),
    );
  }
}
