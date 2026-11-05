part of 'activity_bloc.dart';

enum ActivityStatus { loading, success }

final class ActivityState extends Equatable {
  const ActivityState({
    this.status = ActivityStatus.loading,
    this.entries = const [],
  });

  final ActivityStatus status;

  /// Log entries, oldest first (as stored).
  final List<String> entries;

  /// [entries] for display, newest first.
  List<String> get latestFirst => entries.reversed.toList();

  ActivityState copyWith({ActivityStatus? status, List<String>? entries}) {
    return ActivityState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object> get props => [status, entries];
}
