import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../keys.dart';
import '../notes_providers.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activeFilterProvider);

    return SegmentedButton<NoteFilter>(
      segments: [
        for (final f in NoteFilter.values)
          ButtonSegment(
            value: f,
            label: Text(f.name, key: AppKeys.filter(f.name)),
          ),
      ],
      selected: {filter},
      onSelectionChanged: (selection) =>
          ref.read(activeFilterProvider.notifier).select(selection.single),
    );
  }
}
