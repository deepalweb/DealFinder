import 'package:flutter/material.dart';
import '../models/category.dart';

IconData getCategoryIcon(String category) {
  switch (normalizeCategoryId(category)) {
    case 'food_dining':
      return Icons.restaurant;
    case 'beauty_salon':
      return Icons.content_cut;
    case 'repairs_services':
      return Icons.build;
    case 'shopping_retail':
      return Icons.shopping_bag;
    case 'health_wellness':
      return Icons.favorite;
    case 'daily_essentials':
      return Icons.local_grocery_store;
    case 'auto_services':
      return Icons.directions_car;
    case 'education_courses':
      return Icons.school;
    case 'entertainment_activities':
      return Icons.movie;
    default:
      return Icons.store;
  }
}

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;
  final bool outlined;
  const CategoryIcon(
      {super.key,
      required this.category,
      this.size = 20,
      this.color,
      this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: outlined
            ? Border.all(color: color ?? Colors.blueGrey, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blueGrey).withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        getCategoryIcon(category),
        size: size,
        color: color ?? Colors.blueGrey,
      ),
    );
  }
}
