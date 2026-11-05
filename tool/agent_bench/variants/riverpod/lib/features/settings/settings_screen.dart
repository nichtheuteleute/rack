import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../keys.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loaded at startup (see `AppStartup` in main.dart).
    final newestFirst = ref.watch(newestFirstProvider).requireValue;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            key: AppKeys.newestFirst,
            title: const Text('Newest first'),
            value: newestFirst,
            onChanged: ref.read(newestFirstProvider.notifier).change,
          ),
        ],
      ),
    );
  }
}
