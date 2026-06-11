import 'package:flutter/material.dart';

class DealVerificationBadge extends StatelessWidget {
  final bool compact;
  final String status;
  final String? label;

  const DealVerificationBadge({
    super.key,
    this.compact = true,
    this.status = 'verified',
    this.label,
  });

  ({
    IconData icon,
    Color bg,
    Color border,
    Color fg,
    String label,
    String tooltip
  }) get _style {
    switch (status) {
      case 'reported':
        return (
          icon: Icons.report_problem_outlined,
          bg: const Color(0xFFFFF3E0),
          border: const Color(0xFFFFCC80),
          fg: const Color(0xFFE65100),
          label: label ?? 'Reported',
          tooltip: 'Users reported an issue with this deal',
        );
      case 'worked':
        return (
          icon: Icons.check_circle_outline,
          bg: const Color(0xFFE8F5E9),
          border: const Color(0xFFA5D6A7),
          fg: const Color(0xFF1B5E20),
          label: label ?? 'Worked',
          tooltip: 'Users recently marked this deal as working',
        );
      case 'redeemed':
        return (
          icon: Icons.qr_code_2_rounded,
          bg: const Color(0xFFE3F2FD),
          border: const Color(0xFF90CAF9),
          fg: const Color(0xFF0D47A1),
          label: label ?? 'QR redeemed',
          tooltip: 'This deal has been redeemed in store',
        );
      case 'verified':
      default:
        return (
          icon: Icons.verified_rounded,
          bg: const Color(0xFFE8F5E9),
          border: const Color(0xFFA5D6A7),
          fg: const Color(0xFF1B5E20),
          label: label ?? 'Verified',
          tooltip: 'Verified active deal',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 11.0 : 13.0;
    final fontSize = compact ? 10.0 : 11.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    final style = _style;
    return Tooltip(
      message: style.tooltip,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              style.icon,
              size: iconSize,
              color: style.fg,
            ),
            const SizedBox(width: 4),
            Text(
              style.label,
              style: TextStyle(
                fontSize: fontSize,
                color: style.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
