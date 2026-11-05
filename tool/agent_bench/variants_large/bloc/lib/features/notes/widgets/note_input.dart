import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/notes/bloc/notes_bloc.dart';
import 'package:notes_app/keys.dart';

/// Text field plus add button. The draft lives in [NotesBloc]; the
/// controller only mirrors it so the field can be cleared after adding.
class NoteInput extends StatefulWidget {
  const NoteInput({super.key});

  @override
  State<NoteInput> createState() => _NoteInputState();
}

class _NoteInputState extends State<NoteInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<NotesBloc>().add(const NotesDraftSubmitted());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = context.select((NotesBloc bloc) => bloc.state.canAdd);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: AppKeys.input,
              controller: _controller,
              decoration: const InputDecoration(hintText: 'New note'),
              onChanged: (text) =>
                  context.read<NotesBloc>().add(NotesDraftChanged(text)),
              onSubmitted: canAdd ? (_) => _submit() : null,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: AppKeys.add,
            onPressed: canAdd ? _submit : null,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
