import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> mapMarkerIcon(
    String label, Color background, Color foreground) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(2);
  final text = TextPainter(
    text: TextSpan(
        text: label,
        style: TextStyle(
            color: foreground, fontSize: 13, fontWeight: FontWeight.w700)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 130);
  final width = text.width + 24;
  final shape = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, width, 36), const Radius.circular(18));
  canvas.drawRRect(shape, Paint()..color = background);
  canvas.drawRRect(
      shape,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  text.paint(canvas, Offset(14, 20 - text.height / 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(((width + 4) * 2).ceil(), 80);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final icon =
      BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: 2);
  image.dispose();
  picture.dispose();
  return icon;
}

const googleMapDarkStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#202632"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#cbd5e1"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#202632"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#384356"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#142b43"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#243c35"}]}
]''';
