import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/profile_storage.dart';
import 'package:notes_app/features/archive/archive_providers.dart';
import 'package:notes_app/features/export/export_providers.dart';
import 'package:notes_app/features/profile/profile_providers.dart';
import 'package:notes_app/features/settings/settings_providers.dart';

import '../../helpers/container.dart';

void main() {
  test('exportText follows profile name, sort order and archive', () async {
    final container = await createLoadedContainer(
      profile: ProfileStorage(initialName: 'Kim'),
    );
    final export = watch(container, exportTextProvider);

    expect(export(), 'Notes of Kim\n- [x] B\n- [ ] C\n- [ ] A');

    await container.read(newestFirstProvider.notifier).change(true);
    await container.read(profileNameProvider.notifier).save('Lee');
    await container.read(archiveProvider.notifier).archive('c');

    expect(export(), 'Notes of Lee\n- [ ] A\n- [x] B');
  });
}
