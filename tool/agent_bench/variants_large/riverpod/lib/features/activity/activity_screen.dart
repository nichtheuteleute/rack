import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../keys_large.dart';
import 'activity_providers.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(recentActivityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(entries[index], key: LargeKeys.activityEntry(index)),
        ),
      ),
    );
  }
}
