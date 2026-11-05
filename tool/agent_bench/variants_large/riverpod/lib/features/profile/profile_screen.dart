import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../keys_large.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // The draft name is ephemeral widget state, prefilled once from the
  // stored name (loaded at startup, see `AppStartup` in main.dart).
  late final _controller = TextEditingController(
    text: ref.read(profileNameProvider).requireValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              key: LargeKeys.profileName,
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, _) => FilledButton(
                key: LargeKeys.profileSave,
                onPressed: canSaveProfileName(value.text)
                    ? () => ref
                          .read(profileNameProvider.notifier)
                          .save(value.text)
                    : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
