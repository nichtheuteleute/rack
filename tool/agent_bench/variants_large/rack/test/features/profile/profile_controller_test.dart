import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/features/profile/profile_controller.dart';
import 'package:notes_app/features/profile/profile_store.dart';

void main() {
  late ProfileStorage storage;
  late ProfileStore profile;
  late ProfileController controller;

  setUp(() async {
    storage = ProfileStorage(initialName: 'Alex');
    profile = ProfileStore(storage);
    await profile.load();
    controller = ProfileController(profileStore: profile);
  });

  tearDown(() => controller.dispose());

  test('prefills the field with the saved name', () {
    expect(controller.name.text, 'Alex');
    expect(controller.canSave.value, isTrue);
  });

  test('cannot save a blank name', () {
    controller.name.text = '   ';
    expect(controller.canSave.value, isFalse);
  });

  test('saves the trimmed name', () async {
    controller.name.text = '  Sam ';
    await controller.save();

    expect(profile.name.value, 'Sam');
    expect(await storage.loadName(), 'Sam');
  });
}
