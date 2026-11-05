import 'package:flutter/material.dart';
import 'package:rack/rack.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../keys_large.dart';
import '../notes/notes_module.dart';
import 'note_search_controller.dart';

class SearchScreen extends RackWidget<NoteSearchController> {
  const SearchScreen({super.key});

  @override
  NoteSearchController create(Rack rack) =>
      NoteSearchController(notesStore: rack.module<NotesModule>().notes);

  @override
  Widget buildContent(BuildContext context, NoteSearchController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: LargeKeys.searchInput,
              controller: controller.query,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search notes',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final results = controller.results.value;
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) => ListTile(
                    key: LargeKeys.searchResult(results[index].id),
                    title: Text(results[index].text),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
