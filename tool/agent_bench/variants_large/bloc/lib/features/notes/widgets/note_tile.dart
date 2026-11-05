import 'package:flutter/material.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/keys.dart';
import 'package:notes_app/keys_large.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onToggled,
    required this.onArchived,
  });

  final Note note;
  final VoidCallback onToggled;
  final VoidCallback onArchived;

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
      trailing: IconButton(
        key: LargeKeys.archive(note.id),
        tooltip: 'Archive',
        icon: const Icon(Icons.archive_outlined),
        onPressed: onArchived,
      ),
    );
  }
}
