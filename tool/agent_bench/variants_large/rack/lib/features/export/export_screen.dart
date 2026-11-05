import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys_large.dart';
import '../notes/notes_module.dart';
import '../profile/profile_module.dart';
import 'export_controller.dart';

class ExportScreen extends RackWidget<ExportController> {
  const ExportScreen({super.key});

  @override
  ExportController create(Rack rack) => ExportController(
        profileStore: rack.module<ProfileModule>().profile,
        notesStore: rack.module<NotesModule>().notes,
      );

  @override
  Widget buildContent(BuildContext context, ExportController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SignalBuilder(
          builder: (context) =>
              Text(controller.text.value, key: LargeKeys.exportText),
        ),
      ),
    );
  }
}
