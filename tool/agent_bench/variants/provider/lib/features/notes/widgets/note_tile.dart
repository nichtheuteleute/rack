import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/note.dart';
import '../../../keys.dart';
import '../notes_model.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: AppKeys.tile(note.id),
      title: Text(note.text),
      leading: Checkbox(
        key: AppKeys.toggle(note.id),
        value: note.done,
        onChanged: (_) => context.read<NotesModel>().toggle(note.id),
      ),
    );
  }
}
