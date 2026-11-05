import 'package:rack/rack.dart';

import '../../data/profile_storage.dart';
import 'profile_store.dart';

/// Provides the [ProfileStore]. Loads the stored name in [init].
class ProfileModule extends RackModule {
  ProfileModule({required ProfileStorage storage})
      : _storage = storage,
        super(dependsOn: const []);

  final ProfileStorage _storage;

  late final profile = use(ProfileStore(_storage));

  @override
  Future<void> init() => profile.load();
}
