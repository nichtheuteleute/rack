import 'package:rack/rack.dart';

import '../../data/settings_storage.dart';
import 'settings_store.dart';

/// Provides the [SettingsStore]. Loads the stored settings in [init].
class SettingsModule extends RackModule {
  SettingsModule({required SettingsStorage storage})
      : _storage = storage,
        super(dependsOn: const []);

  final SettingsStorage _storage;

  late final settings = use(SettingsStore(_storage));

  @override
  Future<void> init() => settings.load();
}
