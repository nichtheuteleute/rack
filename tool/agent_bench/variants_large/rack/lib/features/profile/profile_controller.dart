import 'package:flutter/widgets.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'profile_store.dart';

/// Controller of the profile screen: edits the name before saving it.
class ProfileController implements Disposable {
  ProfileController({required ProfileStore profileStore})
      : _profile = profileStore,
        name = TextEditingController(text: profileStore.name.value);

  final ProfileStore _profile;

  /// Text of the name field, prefilled with the saved name.
  final TextEditingController name;
  late final _nameValue = name.toSignal();

  /// Whether the field holds a name that can be saved.
  late final ReadonlySignal<bool> canSave =
      computed(() => _nameValue.value.text.trim().isNotEmpty);

  /// Saves the trimmed name.
  Future<void> save() async {
    final trimmed = name.text.trim();
    if (trimmed.isEmpty) return;
    await _profile.saveName(trimmed);
  }

  @override
  void dispose() {
    canSave.dispose();
    _nameValue.dispose();
    name.dispose();
  }
}
