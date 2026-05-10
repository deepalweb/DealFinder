import 'package:flutter/material.dart';

class DealVerificationBadge extends StatelessWidget {
  final bool compact;

  const DealVerificationBadge({
    super.key,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 11.0 : 13.0;
    final fontSize = compact ? 10.0 : 11.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Tooltip(
      message: 'Verified active deal',
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: iconSize,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF1B5E20),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
