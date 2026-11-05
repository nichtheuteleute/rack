import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../notes/notes_providers.dart';
import '../profile/profile_providers.dart';

part 'export_providers.g.dart';

/// The notes as a plain-text checklist, headed by the profile name, in the
/// current sort order (the notes screen's filter is ignored).
@riverpod
String exportText(Ref ref) {
  final name = ref.watch(profileNameProvider).requireValue;
  final notes = ref.watch(sortedNotesProvider);
  return [
    'Notes of $name',
    for (final note in notes) '- [${note.done ? 'x' : ' '}] ${note.text}',
  ].join('\n');
}
