import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;
  final String token;
  const FavoritesScreen({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Promotion>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = ApiService().fetchFavorites(widget.userId, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: FutureBuilder<List<Promotion>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }
          final favorites = snapshot.data!;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final promotion = favorites[index];
              // You can use your DealCard widget here
              return ListTile(
                title: Text(promotion.title),
                subtitle: Text(promotion.description),
              );
            },
          );
        },
      ),
    );
  }
}
