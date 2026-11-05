part of 'archive_bloc.dart';

enum ArchiveStatus { loading, success }

final class ArchiveState extends Equatable {
  const ArchiveState({
    this.status = ArchiveStatus.loading,
    this.notes = const [],
  });

  final ArchiveStatus status;

  /// Archived notes, in the order they were archived.
  final List<Note> notes;

  ArchiveState copyWith({ArchiveStatus? status, List<Note>? notes}) {
    return ArchiveState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object> get props => [status, notes];
}
