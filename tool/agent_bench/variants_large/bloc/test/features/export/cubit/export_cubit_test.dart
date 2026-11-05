import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/features/export/export.dart';

void main() {
  final open = Note(id: 'a', text: 'Open', createdAt: DateTime(2026, 1, 1));
  final done = Note(
    id: 'b',
    text: 'Done',
    createdAt: DateTime(2026, 1, 2),
    done: true,
  );

  test('ExportState.text lists the notes in the given order', () {
    expect(
      ExportState(name: 'Kim', notes: [done, open]).text,
      'Notes of Kim\n- [x] Done\n- [ ] Open',
    );
    expect(const ExportState(name: 'Kim', notes: []).text, 'Notes of Kim');
  });

  blocTest<ExportCubit, ExportState>(
    'follows name and notes changes',
    build: () => ExportCubit(name: 'Kim', notes: [open]),
    act: (cubit) => cubit
      ..nameChanged('Sam')
      ..notesChanged([open, done]),
    expect: () => [
      ExportState(name: 'Sam', notes: [open]),
      ExportState(name: 'Sam', notes: [open, done]),
    ],
  );
}
