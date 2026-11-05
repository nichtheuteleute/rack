import 'package:signals_flutter/signals_flutter.dart';

import 'activity_store.dart';

/// Controller of the activity screen.
class ActivityController {
  ActivityController({required ActivityStore activityStore})
      : _activity = activityStore;

  final ActivityStore _activity;

  /// Log entries, newest first.
  ReadonlySignal<List<String>> get entries => _activity.entries;
}
