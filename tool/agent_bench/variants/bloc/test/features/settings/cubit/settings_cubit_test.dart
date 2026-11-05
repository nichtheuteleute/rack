import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/settings_storage.dart';
import 'package:notes_app/features/settings/settings.dart';

void main() {
  group('SettingsCubit', () {
    late SettingsStorage storage;

    setUp(() => storage = SettingsStorage(initialNewestFirst: true));

    SettingsCubit buildCubit() => SettingsCubit(settingsStorage: storage);

    test('starts loading with oldest first', () {
      expect(buildCubit().state, const SettingsState());
    });

    blocTest<SettingsCubit, SettingsState>(
      'load emits the stored setting',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => const [
        SettingsState(status: SettingsStatus.success, newestFirst: true),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setNewestFirst emits and persists the new value',
      build: buildCubit,
      seed: () => const SettingsState(
        status: SettingsStatus.success,
        newestFirst: true,
      ),
      act: (cubit) => cubit.setNewestFirst(false),
      expect: () => const [
        SettingsState(status: SettingsStatus.success, newestFirst: false),
      ],
      verify: (_) async {
        expect(await storage.loadNewestFirst(), isFalse);
      },
    );
  });
}
