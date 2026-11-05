import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../keys.dart';
import '../notes_controller.dart';

/// Text field and add button for a new note.
class NoteInput extends SignalWidget {
  const NoteInput({super.key, required this.controller});

  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: AppKeys.input,
              controller: controller.input,
              decoration: const InputDecoration(hintText: 'New note'),
              onSubmitted: (_) => controller.add(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            key: AppKeys.add,
            onPressed: controller.canAdd.value ? controller.add : null,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
