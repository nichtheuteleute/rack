import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys.dart';
import 'settings_controller.dart';
import 'settings_module.dart';

class SettingsScreen extends RackWidget<SettingsController> {
  const SettingsScreen({super.key});

  @override
  SettingsController create(Rack rack) => SettingsController(
        settingsStore: rack.module<SettingsModule>().settings,
      );

  @override
  Widget buildContent(BuildContext context, SettingsController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SignalBuilder(
            builder: (context) => SwitchListTile(
              key: AppKeys.newestFirst,
              title: const Text('Newest first'),
              value: controller.newestFirst.value,
              onChanged: controller.setNewestFirst,
            ),
          ),
        ],
      ),
    );
  }
}
