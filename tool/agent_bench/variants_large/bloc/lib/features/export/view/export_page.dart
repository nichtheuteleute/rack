import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/features/export/cubit/export_cubit.dart';
import 'package:notes_app/features/notes/notes.dart';
import 'package:notes_app/features/profile/profile.dart';
import 'package:notes_app/keys_large.dart';

/// Provides the [ExportCubit] and keeps it in sync with the profile name and
/// the sorted notes (which already reflect the sort-order setting).
class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const ExportPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExportCubit(
        name: context.read<ProfileCubit>().state.name,
        notes: context.read<NotesBloc>().state.sortedNotes,
      ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProfileCubit, ProfileState>(
            listenWhen: (previous, current) => previous.name != current.name,
            listener: (context, state) =>
                context.read<ExportCubit>().nameChanged(state.name),
          ),
          BlocListener<NotesBloc, NotesState>(
            listenWhen: (previous, current) =>
                previous.notes != current.notes ||
                previous.newestFirst != current.newestFirst,
            listener: (context, state) =>
                context.read<ExportCubit>().notesChanged(state.sortedNotes),
          ),
        ],
        child: const ExportView(),
      ),
    );
  }
}

class ExportView extends StatelessWidget {
  const ExportView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.select((ExportCubit cubit) => cubit.state.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(text, key: LargeKeys.exportText),
      ),
    );
  }
}
