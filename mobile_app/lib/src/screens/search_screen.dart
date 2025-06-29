import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Deals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter product, category, or merchant...',
                // Using the global theme for InputDecoration
                // suffixIcon: IconButton( // Suffix icon can be added if desired
                //   icon: const Icon(Icons.clear),
                //   onPressed: () => _searchController.clear(),
                // ),
              ),
              onSubmitted: (value) {
                // Placeholder for when search is submitted
                print('Search submitted: $value');
                // TODO: Implement actual search logic or pass query back
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searched for: $value (Actual search TBD)')),
                );
              },
            ),
            const SizedBox(height: 20),
            // Placeholder for search results
            // Expanded(
            //   child: ListView.builder(
            //     // itemCount: _searchResults.length, // Example
            //     itemBuilder: (context, index) {
            //       // return ListTile(title: Text(_searchResults[index])); // Example
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
