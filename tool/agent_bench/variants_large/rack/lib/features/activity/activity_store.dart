import 'dart:async';

import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../data/activity_storage.dart';
import '../notes/note_event.dart';

/// The activity log. Records an entry for every [NoteEvent] and saves the
/// whole log (oldest first) on every change.
class ActivityStore implements Disposable {
  ActivityStore(this._storage, {required Stream<NoteEvent> noteEvents}) {
    _subscription = noteEvents.listen(_record);
  }

  final ActivityStorage _storage;
  late final StreamSubscription<NoteEvent> _subscription;

  /// Oldest first, as stored.
  final _entries = signal<List<String>>(const []);

  /// The log entries, newest first.
  late final ReadonlySignal<List<String>> entries =
      computed(() => _entries.value.reversed.toList());

  Future<void> load() async {
    _entries.value = await _storage.load();
  }

  Future<void> _record(NoteEvent event) {
    final entry = switch (event) {
      NoteAdded(:final note) => 'Added: ${note.text}',
      NoteCompleted(:final note) => 'Completed: ${note.text}',
    };
    _entries.value = [..._entries.value, entry];
    return _storage.save(_entries.value);
  }

  @override
  void dispose() => _subscription.cancel();
}
