import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../keys.dart';
import '../notes_model.dart';

/// Text field plus add button. Owns only the ephemeral input text;
/// validation and adding live in [NotesModel].
class AddNoteBar extends StatefulWidget {
  const AddNoteBar({super.key});

  @override
  State<AddNoteBar> createState() => _AddNoteBarState();
}

class _AddNoteBarState extends State<AddNoteBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    context.read<NotesModel>().add(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.read<NotesModel>();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: AppKeys.input,
              controller: _controller,
              decoration: const InputDecoration(hintText: 'New note'),
              onSubmitted: (text) {
                if (notes.canAdd(text)) _add();
              },
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) => FilledButton(
              key: AppKeys.add,
              onPressed: notes.canAdd(value.text) ? _add : null,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
