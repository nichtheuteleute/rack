import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../keys.dart';
import 'settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final newestFirst = context.select((SettingsModel s) => s.newestFirst);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            key: AppKeys.newestFirst,
            title: const Text('Newest first'),
            value: newestFirst,
            onChanged: context.read<SettingsModel>().setNewestFirst,
          ),
        ],
      ),
    );
  }
}
