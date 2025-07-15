import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'fashion':
      return Icons.checkroom;
    case 'electronics':
      return Icons.devices;
    case 'food':
      return Icons.restaurant;
    case 'travel':
      return Icons.flight;
    case 'health':
      return Icons.local_hospital;
    case 'entertainment':
      return Icons.movie;
    case 'home':
      return Icons.home;
    case 'pets':
      return Icons.pets;
    default:
      return Icons.store;
  }
}

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;
  final bool outlined;
  const CategoryIcon({super.key, required this.category, this.size = 20, this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: outlined ? Border.all(color: color ?? Colors.blueGrey, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(31, (color ?? Colors.blueGrey).red, (color ?? Colors.blueGrey).green, (color ?? Colors.blueGrey).blue),
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
