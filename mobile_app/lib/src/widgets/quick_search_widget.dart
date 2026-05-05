import 'package:flutter/material.dart';
import '../screens/advanced_search_screen.dart';

class QuickSearchWidget extends StatefulWidget {
  const QuickSearchWidget({super.key});

  @override
  State<QuickSearchWidget> createState() => _QuickSearchWidgetState();
}

class _QuickSearchWidgetState extends State<QuickSearchWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performQuickSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedSearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search deals, categories, merchants...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          onTap: () => _performQuickSearch(_searchController.text),
          readOnly: true,
        ),
        
        // Quick search chips
        Container(
          margin: const EdgeInsets.only(top: 12),
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickSearchChip('Food & Drinks', Icons.restaurant),
              _buildQuickSearchChip('Electronics', Icons.devices),
              _buildQuickSearchChip('Fashion', Icons.checkroom),
              _buildQuickSearchChip('Travel', Icons.flight),
              _buildQuickSearchChip('Beauty', Icons.spa),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSearchChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _searchController.text = label;
          _performQuickSearch(label);
        },
      ),
    );
  }
}
