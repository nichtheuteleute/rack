import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../keys.dart';
import '../notes_providers.dart';

/// Text field and button to add a note. The draft text is ephemeral widget
/// state; validation and adding live in [Notes].
class AddNoteBar extends ConsumerStatefulWidget {
  const AddNoteBar({super.key});

  @override
  ConsumerState<AddNoteBar> createState() => _AddNoteBarState();
}

class _AddNoteBarState extends ConsumerState<AddNoteBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (!canAddNote(_controller.text)) return;
    ref.read(notesProvider.notifier).add(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: AppKeys.input,
              controller: _controller,
              decoration: const InputDecoration(hintText: 'New note'),
              onSubmitted: (_) => _add(),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) => FilledButton(
              key: AppKeys.add,
              onPressed: canAddNote(value.text) ? _add : null,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
