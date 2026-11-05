part of 'profile_cubit.dart';

enum ProfileStatus { loading, success }

final class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.loading, this.name = ''});

  final ProfileStatus status;
  final String name;

  ProfileState copyWith({ProfileStatus? status, String? name}) {
    return ProfileState(status: status ?? this.status, name: name ?? this.name);
  }

  @override
  List<Object> get props => [status, name];
}
