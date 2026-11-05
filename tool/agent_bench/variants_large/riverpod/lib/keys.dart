// SHARED FILE — keys used by the acceptance tests. Add keys, never rename.
import 'package:flutter/widgets.dart';

abstract final class AppKeys {
  /// Shown while the app is loading its data at startup.
  static const loading = Key('app.loading');

  /// Text field for a new note.
  static const input = Key('notes.input');

  /// Button that adds the note from [input]. Disabled while the input is
  /// empty or whitespace only.
  static const add = Key('notes.add');

  /// Text in the app bar: `"<n> open"`, e.g. `"2 open"`.
  static const openCount = Key('notes.openCount');

  /// Tappable filter segment; [name] is `all`, `open` or `done`.
  static Key filter(String name) => Key('notes.filter.$name');

  /// The list tile of a note.
  static Key tile(String id) => Key('notes.tile.$id');

  /// The checkbox that toggles a note's done state.
  static Key toggle(String id) => Key('notes.toggle.$id');

  /// App bar button that opens the settings screen.
  static const settings = Key('nav.settings');

  /// Switch on the settings screen: show newest notes first.
  static const newestFirst = Key('settings.newestFirst');
}
