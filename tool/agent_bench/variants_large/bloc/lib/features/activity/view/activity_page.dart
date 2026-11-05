import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/activity/bloc/activity_bloc.dart';
import 'package:notes_app/keys_large.dart';

/// Activity log screen. Reads the app-wide [ActivityBloc].
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const ActivityPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          final entries = state.latestFirst;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(entries[index], key: LargeKeys.activityEntry(index)),
            ),
          );
        },
      ),
    );
  }
}
