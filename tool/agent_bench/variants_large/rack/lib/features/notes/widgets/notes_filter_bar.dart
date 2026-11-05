import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../keys.dart';
import '../notes_controller.dart';
import '../notes_filter.dart';

/// Segmented control for the notes filter: all, open or done.
class NotesFilterBar extends SignalWidget {
  const NotesFilterBar({super.key, required this.controller});

  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<NotesFilter>(
      segments: [
        for (final filter in NotesFilter.values)
          ButtonSegment(
            value: filter,
            label: Text(_label(filter), key: AppKeys.filter(filter.name)),
          ),
      ],
      selected: {controller.filter.value},
      onSelectionChanged: (selection) =>
          controller.selectFilter(selection.single),
    );
  }

  static String _label(NotesFilter filter) => switch (filter) {
        NotesFilter.all => 'All',
        NotesFilter.open => 'Open',
        NotesFilter.done => 'Done',
      };
}
