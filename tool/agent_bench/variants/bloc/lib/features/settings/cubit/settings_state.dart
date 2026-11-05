part of 'settings_cubit.dart';

enum SettingsStatus { loading, success }

final class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.loading,
    this.newestFirst = false,
  });

  final SettingsStatus status;

  /// Whether notes are listed newest first.
  final bool newestFirst;

  SettingsState copyWith({SettingsStatus? status, bool? newestFirst}) {
    return SettingsState(
      status: status ?? this.status,
      newestFirst: newestFirst ?? this.newestFirst,
    );
  }

  @override
  List<Object> get props => [status, newestFirst];
}
