import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/settings/cubit/settings_cubit.dart';
import 'package:notes_app/keys.dart';

/// Settings screen. Reads the app-wide [SettingsCubit] provided by `App`.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    final newestFirst = context.select(
      (SettingsCubit cubit) => cubit.state.newestFirst,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            key: AppKeys.newestFirst,
            title: const Text('Newest first'),
            value: newestFirst,
            onChanged: context.read<SettingsCubit>().setNewestFirst,
          ),
        ],
      ),
    );
  }
}
