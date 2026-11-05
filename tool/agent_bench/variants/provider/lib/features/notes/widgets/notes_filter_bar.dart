import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../keys.dart';
import '../notes_model.dart';

class NotesFilterBar extends StatelessWidget {
  const NotesFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.select((NotesModel m) => m.filter);
    return SegmentedButton<NotesFilter>(
      segments: [
        for (final f in NotesFilter.values)
          ButtonSegment(
            value: f,
            label: Text(f.name, key: AppKeys.filter(f.name)),
          ),
      ],
      selected: {filter},
      onSelectionChanged: (selection) =>
          context.read<NotesModel>().setFilter(selection.single),
    );
  }
}
