import 'package:flutter/material.dart';
import 'package:notes_app/features/activity/activity.dart';
import 'package:notes_app/features/archive/archive.dart';
import 'package:notes_app/features/export/export.dart';
import 'package:notes_app/features/profile/profile.dart';
import 'package:notes_app/features/search/search.dart';
import 'package:notes_app/keys_large.dart';

/// Navigation to the other features; the notes screen is the app's hub.
class NotesDrawer extends StatelessWidget {
  const NotesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            _NavTile(
              key: LargeKeys.navProfile,
              icon: Icons.person_outline,
              title: 'Profile',
              route: ProfilePage.route,
            ),
            _NavTile(
              key: LargeKeys.navActivity,
              icon: Icons.history,
              title: 'Activity',
              route: ActivityPage.route,
            ),
            _NavTile(
              key: LargeKeys.navArchive,
              icon: Icons.archive_outlined,
              title: 'Archive',
              route: ArchivePage.route,
            ),
            _NavTile(
              key: LargeKeys.navExport,
              icon: Icons.ios_share,
              title: 'Export',
              route: ExportPage.route,
            ),
            _NavTile(
              key: LargeKeys.navSearch,
              icon: Icons.search,
              title: 'Search',
              route: SearchPage.route,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final Route<void> Function() route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.of(context)
        ..pop()
        ..push(route()),
    );
  }
}
