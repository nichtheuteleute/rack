import 'package:flutter/material.dart';

import '../../../keys_large.dart';
import '../../activity/activity_screen.dart';
import '../../archive/archive_screen.dart';
import '../../export/export_screen.dart';
import '../../profile/profile_screen.dart';
import '../../search/search_screen.dart';

/// Navigation drawer of the notes screen: opens the other feature screens.
class NotesDrawer extends StatelessWidget {
  const NotesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget entry(Key key, IconData icon, String title, Widget screen) =>
        ListTile(
          key: key,
          leading: Icon(icon),
          title: Text(title),
          onTap: () => Navigator.of(context)
            ..pop()
            ..push(MaterialPageRoute<void>(builder: (_) => screen)),
        );

    return Drawer(
      child: ListView(
        children: [
          entry(LargeKeys.navProfile, Icons.person, 'Profile',
              const ProfileScreen()),
          entry(LargeKeys.navActivity, Icons.history, 'Activity',
              const ActivityScreen()),
          entry(LargeKeys.navArchive, Icons.archive, 'Archive',
              const ArchiveScreen()),
          entry(LargeKeys.navExport, Icons.ios_share, 'Export',
              const ExportScreen()),
          entry(LargeKeys.navSearch, Icons.search, 'Search',
              const SearchScreen()),
        ],
      ),
    );
  }
}
