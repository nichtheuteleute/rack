import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/features/profile/profile.dart';

void main() {
  group('ProfileCubit', () {
    late ProfileStorage storage;

    setUp(() => storage = ProfileStorage(initialName: 'Kim'));

    blocTest<ProfileCubit, ProfileState>(
      'load emits the stored name',
      build: () => ProfileCubit(profileStorage: storage),
      act: (cubit) => cubit.load(),
      expect: () => const [
        ProfileState(status: ProfileStatus.success, name: 'Kim'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'saveName emits and persists the name',
      build: () => ProfileCubit(profileStorage: storage),
      seed: () =>
          const ProfileState(status: ProfileStatus.success, name: 'Kim'),
      act: (cubit) => cubit.saveName('Sam'),
      expect: () => const [
        ProfileState(status: ProfileStatus.success, name: 'Sam'),
      ],
      verify: (_) async => expect(await storage.loadName(), 'Sam'),
    );
  });

  group('ProfileFormCubit', () {
    test('starts with the given name', () {
      final cubit = ProfileFormCubit(name: 'Kim');
      expect(cubit.state.draft, 'Kim');
      expect(cubit.state.canSave, isTrue);
    });

    blocTest<ProfileFormCubit, ProfileFormState>(
      'draftChanged validates the trimmed name',
      build: () => ProfileFormCubit(name: 'Kim'),
      act: (cubit) => cubit
        ..draftChanged('   ')
        ..draftChanged(' Sam '),
      expect: () => [
        isA<ProfileFormState>().having((s) => s.canSave, 'canSave', isFalse),
        isA<ProfileFormState>()
            .having((s) => s.canSave, 'canSave', isTrue)
            .having((s) => s.name, 'name', 'Sam'),
      ],
    );
  });
}
