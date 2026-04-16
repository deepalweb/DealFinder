import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/promotion.dart';

class FlashSaleCard extends StatefulWidget {
  final Promotion promotion;
  final VoidCallback? onTap;
  final double? width;

  const FlashSaleCard({
    super.key,
    required this.promotion,
    this.onTap,
    this.width,
  });

  @override
  State<FlashSaleCard> createState() => _FlashSaleCardState();
}

class _FlashSaleCardState extends State<FlashSaleCard> {
  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (widget.promotion.endDate == null) return;
    
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    if (widget.promotion.endDate == null) return;
    
    final diff = widget.promotion.endDate!.difference(DateTime.now());
    if (mounted) {
      setState(() => _timeLeft = diff.isNegative ? Duration.zero : diff);
    }
  }

  String _formatTime(int value) => value.toString().padLeft(2, '0');

  Widget _buildImage() {
    final img = widget.promotion.imageDataString;
    final shimmer = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );

    if (img == null || img.isEmpty) return shimmer;

    if (img.startsWith('data:image')) {
      try {
        final bytes = base64Decode(img.substring(img.indexOf(',') + 1));
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity,
            errorBuilder: (_, __, ___) => shimmer);
      } catch (_) {
        return shimmer;
      }
    }

    if (img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => shimmer,
        errorWidget: (_, __, ___) => shimmer,
      );
    }

    return shimmer;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promotion;
    final hasTime = _timeLeft != null && _timeLeft!.inSeconds > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width ?? 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with flash badge
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _buildImage(),
                ),
                // Flash badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          p.discount ?? 'FLASH',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Merchant
                  if (p.merchantName != null)
                    Text(
                      p.merchantName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Countdown timer
                  if (hasTime)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, size: 14, color: Color(0xFFFF6F00)),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(_timeLeft!.inHours)}:${_formatTime(_timeLeft!.inMinutes % 60)}:${_formatTime(_timeLeft!.inSeconds % 60)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6F00),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Expired',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
