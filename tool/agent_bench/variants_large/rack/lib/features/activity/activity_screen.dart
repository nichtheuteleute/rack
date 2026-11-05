import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys_large.dart';
import 'activity_controller.dart';
import 'activity_module.dart';

class ActivityScreen extends RackWidget<ActivityController> {
  const ActivityScreen({super.key});

  @override
  ActivityController create(Rack rack) => ActivityController(
        activityStore: rack.module<ActivityModule>().activity,
      );

  @override
  Widget buildContent(BuildContext context, ActivityController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: SignalBuilder(
        builder: (context) {
          final entries = controller.entries.value;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(entries[index], key: LargeKeys.activityEntry(index)),
            ),
          );
        },
      ),
    );
  }
}
