// SHARED FILE — keys of the extension features. Add keys, never rename.
import 'package:flutter/widgets.dart';

abstract final class LargeKeys {
  // Navigation drawer entries (the notes screen has a Drawer).
  static const navProfile = Key('nav.profile');
  static const navActivity = Key('nav.activity');
  static const navArchive = Key('nav.archive');
  static const navExport = Key('nav.export');
  static const navSearch = Key('nav.search');

  // Profile screen.
  static const profileName = Key('profile.name');
  static const profileSave = Key('profile.save');

  // Activity screen: entry 0 is the newest.
  static Key activityEntry(int index) => Key('activity.entry.$index');

  // Notes screen: archive button on each note tile.
  static Key archive(String id) => Key('notes.archive.$id');

  // Archive screen.
  static Key archiveTile(String id) => Key('archive.tile.$id');
  static Key restore(String id) => Key('archive.restore.$id');

  // Export screen.
  static const exportText = Key('export.text');

  // Search screen.
  static const searchInput = Key('search.input');
  static Key searchResult(String id) => Key('search.result.$id');
}
