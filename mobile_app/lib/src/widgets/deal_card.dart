import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';

class DealCard extends StatefulWidget {
  final Promotion promotion;
  final double? width;
  final bool compact; // compact = grid mode, false = list mode

  const DealCard({super.key, required this.promotion, this.width, this.compact = false});

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  bool _isFavorite = false;

  String _getCurrencySymbol() {
    final currency = widget.promotion.merchantCurrency ?? 'LKR';
    const Map<String, String> symbols = {
      'USD': r'$', 'LKR': 'Rs.', 'EUR': '\u20ac', 'GBP': '\u00a3',
      'INR': '\u20b9', 'AUD': 'A\$', 'CAD': 'C\$', 'SGD': 'S\$',
      'AED': 'AED', 'MYR': 'RM',
    };
    return symbols[currency] ?? currency;
  }

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesManager.isFavorite(widget.promotion.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await FavoritesManager.removeFavorite(widget.promotion.id);
    } else {
      await FavoritesManager.addFavorite(widget.promotion.id);
    }
    if (mounted) setState(() => _isFavorite = !_isFavorite);
  }

  Widget _buildImage({required double height}) {
    final img = widget.promotion.imageDataString;

    Widget placeholder = Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(Icons.local_offer, size: height * 0.3, color: Colors.grey[400]),
    );

    if (img == null || img.isEmpty) return placeholder;

    if (img.startsWith('data:image')) {
      try {
        final bytes = base64Decode(img.substring(img.indexOf(',') + 1));
        return Image.memory(bytes, height: height, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder);
      } catch (_) {
        return placeholder;
      }
    }

    if (img.startsWith('http')) {
      return Image.network(
        img, height: height, width: double.infinity, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null ? child : Container(
          height: height, color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.promotion;

    return widget.compact ? _buildCompact(theme, p) : _buildList(theme, p);
  }

  // ── Compact grid card (Temu-style) ──────────────────────────────────────
  Widget _buildCompact(ThemeData theme, Promotion p) {
    return Card(
      margin: const EdgeInsets.all(3),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image — tall, fills most of the card
          Stack(
            children: [
              _buildImage(height: 160),
              // Favorite button
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 15,
                      color: _isFavorite ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              // Discount badge
              if (p.discount != null && p.discount!.isNotEmpty)
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(p.discount!,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              // Featured badge
              if (p.featured == true)
                Positioned(
                  bottom: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('HOT',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          // Info — compact
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.3)),
                const SizedBox(height: 3),
                if (p.merchantName != null && p.merchantName!.isNotEmpty)
                  Text(p.merchantName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                // Price row
                if (p.discountedPrice != null || p.originalPrice != null || p.price != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_getCurrencySymbol()}${(p.discountedPrice ?? p.price ?? p.originalPrice)!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.bold),
                      ),
                      if (p.originalPrice != null && p.discountedPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${_getCurrencySymbol()}${p.originalPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  )
                else
                  Text(p.discount ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold)),
                // Expiry
                if (p.endDate != null) ...[
                  const SizedBox(height: 3),
                  _ExpiryBadge(endDate: p.endDate!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Full list card ────────────────────────────────────────────────────────
  Widget _buildList(ThemeData theme, Promotion p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              _buildImage(height: 160),
              // Discount badge top-left
              if (p.discount != null && p.discount!.isNotEmpty)
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text(p.discount!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              // Featured badge
              if (p.featured == true)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange[700], borderRadius: BorderRadius.circular(8)),
                    child: const Text('FEATURED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              // Action buttons bottom-right
              Positioned(
                bottom: 8, right: 8,
                child: Row(
                  children: [
                    _ImageActionButton(icon: Icons.share, onTap: () {
                      Share.share('🔥 ${p.title}\n${p.description}\n💰 ${p.discount ?? "Great Deal"}');
                    }),
                    const SizedBox(width: 6),
                    _ImageActionButton(
                      icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                      onTap: _toggleFavorite,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Info row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant + expiry row
                Row(
                  children: [
                    if (p.merchantName != null && p.merchantName!.isNotEmpty) ...[
                      Icon(Icons.storefront, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(p.merchantName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ] else
                      const Spacer(),
                    if (p.endDate != null) _ExpiryBadge(endDate: p.endDate!),
                  ],
                ),
                const SizedBox(height: 6),
                // Title
                Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Description
                Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
                // Price row
                if (p.discountedPrice != null || p.price != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (p.originalPrice != null) ...[
                        Text('Rs.${p.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 13)),
                        const SizedBox(width: 8),
                      ],
                      Text('Rs.${(p.discountedPrice ?? p.price)!.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
                // Code
                if (p.code != null && p.code!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Text('CODE: ${p.code}',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final DateTime endDate;
  const _ExpiryBadge({required this.endDate});

  @override
  Widget build(BuildContext context) {
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return const SizedBox.shrink();
    String label;
    Color color;
    if (diff.inDays >= 1) {
      label = '${diff.inDays}d left';
      color = diff.inDays <= 3 ? Colors.orange : Colors.grey;
    } else if (diff.inHours > 0) {
      label = '${diff.inHours}h left';
      color = Colors.red;
    } else {
      label = '${diff.inMinutes}m left';
      color = Colors.red;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer, size: 12, color: color),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _ImageActionButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.grey[700]),
      ),
    );
  }
}
