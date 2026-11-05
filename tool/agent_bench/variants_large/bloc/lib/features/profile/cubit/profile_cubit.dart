import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notes_app/data/profile_storage.dart';

part 'profile_state.dart';

/// Owns the stored profile name (app-wide; export shows it).
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this._profileStorage}) : super(const ProfileState());

  final ProfileStorage _profileStorage;

  Future<void> load() async {
    final name = await _profileStorage.loadName();
    emit(ProfileState(status: ProfileStatus.success, name: name));
  }

  Future<void> saveName(String name) async {
    emit(state.copyWith(name: name));
    await _profileStorage.saveName(name);
  }
}
