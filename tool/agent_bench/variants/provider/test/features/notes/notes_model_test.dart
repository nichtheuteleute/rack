import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/note.dart';
import 'package:notes_app/data/notes_storage.dart';
import 'package:notes_app/features/notes/notes_model.dart';

void main() {
  late NotesStorage storage;
  late NotesModel model;
  late int notified;

  setUp(() async {
    storage = NotesStorage(
      initial: [
        Note(id: 'b', text: 'second', createdAt: DateTime(2026, 1, 2)),
        Note(
          id: 'a',
          text: 'first',
          createdAt: DateTime(2026, 1, 1),
          done: true,
        ),
        Note(id: 'c', text: 'third', createdAt: DateTime(2026, 1, 3)),
      ],
    );
    model = NotesModel(storage);
    await model.load();
    notified = 0;
    model.addListener(() => notified++);
  });

  List<String> visibleIds() => [for (final n in model.visibleNotes) n.id];

  test('load sorts by createdAt and counts open notes', () {
    expect(model.isLoaded, isTrue);
    expect(visibleIds(), ['a', 'b', 'c']);
    expect(model.openCount, 2);
  });

  test('newestFirst reverses the order and notifies', () {
    model.newestFirst = true;

    expect(visibleIds(), ['c', 'b', 'a']);
    expect(notified, 1);
  });

  test('filter selects open or done notes', () {
    model.setFilter(NotesFilter.open);
    expect(visibleIds(), ['b', 'c']);

    model.setFilter(NotesFilter.done);
    expect(visibleIds(), ['a']);

    model.setFilter(NotesFilter.all);
    expect(visibleIds(), ['a', 'b', 'c']);
    expect(notified, 3);
  });

  test('canAdd rejects blank text', () {
    expect(model.canAdd(''), isFalse);
    expect(model.canAdd('   '), isFalse);
    expect(model.canAdd(' x '), isTrue);
  });

  test('add trims the text, appends the note and persists', () async {
    await model.add('  new note  ');

    final added = model.visibleNotes.last;
    expect(added.text, 'new note');
    expect(added.id, 'n100');
    expect(added.done, isFalse);
    expect(model.openCount, 3);
    expect(notified, 1);
    expect(storage.saveCount, 1);
    expect((await storage.load()).map((n) => n.id), contains('n100'));
  });

  test('add ignores blank text', () async {
    await model.add('   ');

    expect(model.visibleNotes, hasLength(3));
    expect(notified, 0);
    expect(storage.saveCount, 0);
  });

  test('toggle flips done and persists', () async {
    await model.toggle('b');

    expect(model.openCount, 1);
    expect(model.visibleNotes.firstWhere((n) => n.id == 'b').done, isTrue);
    expect(storage.saveCount, 1);
    expect((await storage.load()).firstWhere((n) => n.id == 'b').done, isTrue);
  });
}
