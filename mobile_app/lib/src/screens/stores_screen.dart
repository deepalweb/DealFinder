import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'deals_list_screen.dart'; // Import the DealsListScreen

class StoresScreen extends StatelessWidget {
  const StoresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService().fetchMerchants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No stores found.'));
          }
          final merchants = snapshot.data!;
          return ListView.builder(
            itemCount: merchants.length,
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(merchant['name'] ?? 'Unnamed Store'),
                subtitle: Text(merchant['description'] ?? ''),
                onTap: () {
                  // Navigate to a merchant's deals list
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DealsListScreen(
                        categoryFilter: null, // Or pass a merchant filter if supported
                        // You can add a merchantId parameter to DealsListScreen if you want to filter by merchant
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
