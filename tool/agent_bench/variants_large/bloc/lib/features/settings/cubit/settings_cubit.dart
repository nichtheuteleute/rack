import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/settings_storage.dart';

part 'settings_state.dart';

/// Owns the user settings: loads them once and persists every change.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this._settingsStorage})
    : super(const SettingsState());

  final SettingsStorage _settingsStorage;

  Future<void> load() async {
    final newestFirst = await _settingsStorage.loadNewestFirst();
    emit(
      SettingsState(status: SettingsStatus.success, newestFirst: newestFirst),
    );
  }

  Future<void> setNewestFirst(bool value) async {
    emit(state.copyWith(newestFirst: value));
    await _settingsStorage.saveNewestFirst(value);
  }
}
