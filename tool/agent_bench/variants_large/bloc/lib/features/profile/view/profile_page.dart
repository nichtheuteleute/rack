import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/profile/cubit/profile_cubit.dart';
import 'package:notes_app/features/profile/cubit/profile_form_cubit.dart';
import 'package:notes_app/keys_large.dart';

/// Provides a [ProfileFormCubit] that starts from the stored name.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const ProfilePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileFormCubit(name: context.read<ProfileCubit>().state.name),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final _controller = TextEditingController(
    text: context.read<ProfileFormCubit>().state.draft,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = context.read<ProfileFormCubit>().state.name;
    context.read<ProfileCubit>().saveName(name);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = context.select(
      (ProfileFormCubit cubit) => cubit.state.canSave,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: LargeKeys.profileName,
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: context.read<ProfileFormCubit>().draftChanged,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: LargeKeys.profileSave,
              onPressed: canSave ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
