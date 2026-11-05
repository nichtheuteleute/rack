import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'profile_form_state.dart';

/// The name being edited on the profile screen (scoped to that screen, so
/// every visit starts from the stored name).
class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit({required String name})
    : super(ProfileFormState(draft: name));

  void draftChanged(String draft) => emit(ProfileFormState(draft: draft));
}
