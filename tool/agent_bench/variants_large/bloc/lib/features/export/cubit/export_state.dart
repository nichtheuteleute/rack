part of 'export_cubit.dart';

final class ExportState extends Equatable {
  const ExportState({required this.name, required this.notes});

  /// Profile name.
  final String name;

  /// Notes in the current sort order (not filtered, not archived).
  final List<Note> notes;

  String get text => [
    'Notes of $name',
    for (final note in notes) '- [${note.done ? 'x' : ' '}] ${note.text}',
  ].join('\n');

  ExportState copyWith({String? name, List<Note>? notes}) {
    return ExportState(name: name ?? this.name, notes: notes ?? this.notes);
  }

  @override
  List<Object> get props => [name, notes];
}
