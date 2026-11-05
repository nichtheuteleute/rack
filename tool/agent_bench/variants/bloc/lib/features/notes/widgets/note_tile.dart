import 'package:flutter/material.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/keys.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, required this.onToggled});

  final Note note;
  final VoidCallback onToggled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        key: AppKeys.toggle(note.id),
        value: note.done,
        onChanged: (_) => onToggled(),
      ),
      title: Text(
        note.text,
        style: note.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
    );
  }
}
