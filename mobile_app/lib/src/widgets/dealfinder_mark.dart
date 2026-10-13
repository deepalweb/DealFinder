import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Resolution-independent brand asset: a ticket with a four-point discovery star.
class DealFinderMark extends StatelessWidget {
  const DealFinderMark({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _MarkPainter()),
        ),
      );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    canvas.scale(scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 64, 64), const Radius.circular(19)),
      Paint()..color = AppColors.ceylonInk,
    );
    final ticket = Path()
      ..moveTo(16, 19)
      ..lineTo(48, 19)
      ..lineTo(48, 27)
      ..arcToPoint(const Offset(48, 37),
          radius: const Radius.circular(5), clockwise: false)
      ..lineTo(48, 45)
      ..lineTo(16, 45)
      ..lineTo(16, 37)
      ..arcToPoint(const Offset(16, 27),
          radius: const Radius.circular(5), clockwise: false)
      ..close();
    canvas.drawPath(ticket, Paint()..color = Colors.white);
    final star = Path()
      ..moveTo(32, 23)
      ..quadraticBezierTo(33, 30, 40, 32)
      ..quadraticBezierTo(33, 34, 32, 41)
      ..quadraticBezierTo(31, 34, 24, 32)
      ..quadraticBezierTo(31, 30, 32, 23)
      ..close();
    canvas.drawPath(star, Paint()..color = AppColors.ceylonInk);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
