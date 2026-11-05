import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../keys_large.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              key: LargeKeys.searchInput,
              decoration: const InputDecoration(hintText: 'Search notes'),
              onChanged: ref.read(searchQueryProvider.notifier).change,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) => ListTile(
                key: LargeKeys.searchResult(results[index].id),
                title: Text(results[index].text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
