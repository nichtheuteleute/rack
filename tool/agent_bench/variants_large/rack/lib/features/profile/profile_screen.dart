import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys_large.dart';
import 'profile_controller.dart';
import 'profile_module.dart';

class ProfileScreen extends RackWidget<ProfileController> {
  const ProfileScreen({super.key});

  @override
  ProfileController create(Rack rack) =>
      ProfileController(profileStore: rack.module<ProfileModule>().profile);

  @override
  Widget buildContent(BuildContext context, ProfileController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              key: LargeKeys.profileName,
              controller: controller.name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            SignalBuilder(
              builder: (context) => FilledButton(
                key: LargeKeys.profileSave,
                onPressed: controller.canSave.value ? controller.save : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
