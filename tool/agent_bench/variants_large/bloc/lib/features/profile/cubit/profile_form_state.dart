part of 'profile_form_cubit.dart';

final class ProfileFormState extends Equatable {
  const ProfileFormState({required this.draft});

  /// Raw text of the name field.
  final String draft;

  /// The name that would be saved.
  String get name => draft.trim();

  bool get canSave => name.isNotEmpty;

  @override
  List<Object> get props => [draft];
}
