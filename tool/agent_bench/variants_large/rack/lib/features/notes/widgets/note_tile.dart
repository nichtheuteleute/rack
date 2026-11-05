import 'package:flutter/material.dart';

import '../../../data/note.dart';
import '../../../keys.dart';
import '../../../keys_large.dart';
import '../notes_controller.dart';

/// One note with a checkbox that toggles its done state and an archive
/// button.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, required this.controller});

  final Note note;
  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: AppKeys.tile(note.id),
      leading: Checkbox(
        key: AppKeys.toggle(note.id),
        value: note.done,
        onChanged: (_) => controller.toggle(note),
      ),
      title: Text(note.text),
      trailing: IconButton(
        key: LargeKeys.archive(note.id),
        tooltip: 'Archive',
        icon: const Icon(Icons.archive_outlined),
        onPressed: () => controller.archive(note),
      ),
    );
  }
}
