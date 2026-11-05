import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/note.dart';
import '../../../keys.dart';
import '../notes_providers.dart';

class NoteTile extends ConsumerWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: AppKeys.tile(note.id),
      leading: Checkbox(
        key: AppKeys.toggle(note.id),
        value: note.done,
        onChanged: (_) => ref.read(notesProvider.notifier).toggle(note.id),
      ),
      title: Text(note.text),
    );
  }
}
