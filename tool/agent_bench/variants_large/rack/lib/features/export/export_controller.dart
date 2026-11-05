import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../notes/notes_store.dart';
import '../profile/profile_store.dart';

/// Controller of the export screen: renders the notes list as a checklist.
class ExportController implements Disposable {
  ExportController({
    required ProfileStore profileStore,
    required NotesStore notesStore,
  })  : _profile = profileStore,
        _notes = notesStore;

  final ProfileStore _profile;
  final NotesStore _notes;

  /// The export, always in sync with the profile name, the notes and their
  /// sort order (the filter of the notes screen does not apply).
  late final ReadonlySignal<String> text = computed(() => [
        'Notes of ${_profile.name.value}',
        for (final note in _notes.notes.value)
          '- [${note.done ? 'x' : ' '}] ${note.text}',
      ].join('\n'));

  @override
  void dispose() => text.dispose();
}
