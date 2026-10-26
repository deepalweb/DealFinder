import 'package:flutter/material.dart';

class DiscoverCategoryArtwork extends StatelessWidget {
  const DiscoverCategoryArtwork({super.key, required this.category});
  final String category;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child:
          CustomPaint(size: const Size(56, 52), painter: _Artwork(category)));
}

class _Artwork extends CustomPainter {
  _Artwork(this.category);
  final String category;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 80, size.height / 80);
    void rect(double x, double y, double w, double h, Color color,
            [double radius = 4]) =>
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, w, h), Radius.circular(radius)),
            Paint()..color = color);
    void circle(double x, double y, double r, Color color) =>
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    switch (category) {
      case 'food_dining':
        rect(10, 39, 60, 10, const Color(0xFF5B3425), 8);
        rect(8, 32, 64, 7, const Color(0xFF4A9B58), 5);
        rect(12, 47, 56, 13, const Color(0xFFE7A14D), 8);
        canvas.drawPath(
            Path()
              ..moveTo(10, 31)
              ..cubicTo(10, 4, 70, 4, 70, 31)
              ..close(),
            Paint()..color = const Color(0xFFF4BA62));
        for (final pos in [
          const Offset(26, 21),
          const Offset(40, 15),
          const Offset(53, 22)
        ]) {
          canvas.drawOval(Rect.fromCenter(center: pos, width: 5, height: 2),
              Paint()..color = const Color(0xFFFFE4A7));
        }
      case 'daily_essentials':
        rect(17, 28, 46, 42, const Color(0xFFD5AB77), 2);
        circle(28, 22, 13, const Color(0xFF76A56A));
        circle(46, 23, 13, const Color(0xFFF18D52));
        rect(50, 10, 11, 35, const Color(0xFFF0CA76), 5);
        rect(17, 36, 46, 34, const Color(0xFFE7C190), 2);
        canvas.drawArc(
            const Rect.fromLTWH(28, 26, 24, 24),
            0,
            3.14,
            false,
            Paint()
              ..color = const Color(0xFF977748)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      case 'shopping_retail':
        canvas.drawPath(
            Path()
              ..moveTo(25, 15)
              ..lineTo(34, 12)
              ..quadraticBezierTo(40, 22, 46, 12)
              ..lineTo(56, 15)
              ..lineTo(74, 34)
              ..lineTo(61, 44)
              ..lineTo(57, 37)
              ..lineTo(58, 70)
              ..lineTo(22, 70)
              ..lineTo(23, 37)
              ..lineTo(19, 44)
              ..lineTo(6, 34)
              ..close(),
            Paint()..color = const Color(0xFF6B8DCA));
        rect(25, 56, 30, 5, const Color(0xFFABC3EB), 1);
      case 'electronics':
        rect(12, 12, 56, 42, const Color(0xFF46505C), 4);
        rect(16, 16, 48, 33, const Color(0xFF9CC9CF), 2);
        canvas.drawPath(
            Path()
              ..moveTo(12, 54)
              ..lineTo(68, 54)
              ..lineTo(77, 65)
              ..lineTo(3, 65)
              ..close(),
            Paint()..color = const Color(0xFFB0BAC5));
        rect(3, 64, 74, 4, const Color(0xFF667282), 2);
        rect(31, 56, 18, 5, const Color(0xFF8995A3), 1);
      case 'beauty_salon':
        rect(12, 27, 24, 40, const Color(0xFFD2A8C8), 5);
        rect(17, 17, 14, 13, const Color(0xFF5F5269), 2);
        rect(45, 21, 22, 47, const Color(0xFFA8C8B8), 5);
        rect(50, 11, 12, 14, const Color(0xFF456D59), 2);
        rect(50, 9, 21, 4, const Color(0xFF456D59), 1);
        rect(16, 41, 16, 15, const Color(0xFFF4E6F0), 2);
        rect(49, 40, 14, 16, const Color(0xFFE4F2E9), 2);
      case 'health_wellness':
        canvas.save();
        canvas.translate(40, 40);
        canvas.rotate(-.35);
        rect(-24, -4, 48, 8, const Color(0xFF7A8491), 2);
        rect(-29, -15, 12, 30, const Color(0xFF665788), 4);
        rect(17, -15, 12, 30, const Color(0xFF665788), 4);
        rect(-34, -10, 6, 20, const Color(0xFF9382B7), 3);
        rect(28, -10, 6, 20, const Color(0xFF9382B7), 3);
        canvas.restore();
      default:
        for (var y = 0; y < 2; y++) {
          for (var x = 0; x < 2; x++) {
            rect(14 + x * 28.0, 14 + y * 28.0, 22, 22, const Color(0xFF909AA8),
                5);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_Artwork oldDelegate) => oldDelegate.category != category;
}
