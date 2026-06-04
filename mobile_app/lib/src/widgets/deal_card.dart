import 'package:flutter/material.dart';

import '../models/promotion.dart';
import 'modern_deal_card.dart';

class DealCard extends StatelessWidget {
  final Promotion promotion;
  final double? width;
  final bool compact;

  const DealCard({
    super.key,
    required this.promotion,
    this.width,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernDealCard(
      promotion: promotion,
      width: width,
    );
  }
}
