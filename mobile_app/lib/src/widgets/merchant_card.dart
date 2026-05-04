import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/category_icon.dart';

class MerchantCard extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final VoidCallback onVisit;
  final VoidCallback onFollowToggle;
  final bool isFollowing;
  final VoidCallback onShare;
  final bool compact;

  const MerchantCard({
    super.key,
    required this.merchant,
    required this.onVisit,
    required this.onFollowToggle,
    required this.isFollowing,
    required this.onShare,
    this.compact = false,
  });

  Widget _buildImageWidget(
    String? imageUrl,
    Widget placeholder, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes =
            base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (e) {
        if (kDebugMode) print('Error decoding base64 image: $e');
        return placeholder;
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
      );
    }

    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final name = (merchant['name'] ?? 'Unnamed Store').toString();
    final category = (merchant['category'] ?? 'other').toString();
    final description =
        (merchant['description'] ?? merchant['profile'] ?? '').toString();
    final followers = (merchant['followers'] as num?)?.toInt() ?? 0;
    final deals =
        ((merchant['activeDeals'] ?? merchant['deals']) as num?)?.toInt() ?? 0;
    final currency = (merchant['currency'] ?? 'LKR').toString();
    final logoUrl = merchant['logo']?.toString();
    final bannerUrl = merchant['banner']?.toString();
    final location = (merchant['address'] ?? '').toString();

    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    final colorSeed = name.hashCode;
    final gradientColors = _getGradientColors(colorSeed);
    final bannerHeight = compact ? 118.0 : 146.0;
    final logoRadius = compact ? 26.0 : 32.0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onVisit,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EBF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: bannerHeight,
                    width: double.infinity,
                    child: hasBanner
                        ? _buildImageWidget(
                            bannerUrl,
                            _buildGradientBanner(name, gradientColors,
                                height: bannerHeight),
                            height: bannerHeight,
                            width: double.infinity,
                          )
                        : _buildGradientBanner(name, gradientColors,
                            height: bannerHeight),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CategoryIcon(category: category, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _prettyLabel(category),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF243447),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _buildTopAction(
                          icon: isFollowing
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFollowing
                              ? const Color(0xFFE53935)
                              : const Color(0xFF54606E),
                          onTap: onFollowToggle,
                        ),
                        const SizedBox(width: 8),
                        _buildTopAction(
                          icon: Icons.share_outlined,
                          color: const Color(0xFF54606E),
                          onTap: onShare,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: logoRadius,
                            backgroundColor: Colors.white,
                            child: hasLogo
                                ? ClipOval(
                                    child: _buildImageWidget(
                                      logoUrl,
                                      _buildLogoPlaceholder(
                                          name, gradientColors),
                                      width: logoRadius * 2,
                                      height: logoRadius * 2,
                                    ),
                                  )
                                : _buildLogoPlaceholder(name, gradientColors),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  deals > 0
                                      ? '$deals active deals right now'
                                      : 'Explore this merchant profile',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5C6B7A),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (location.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: Color(0xFF7C8896),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C8896),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoPill(
                          icon: Icons.people_outline,
                          label: '$followers followers',
                          background: const Color(0xFFF3F6FA),
                          foreground: const Color(0xFF51606F),
                        ),
                        _buildInfoPill(
                          icon: Icons.local_offer_outlined,
                          label: '$deals deals',
                          background: const Color(0xFFE8F3FF),
                          foreground: const Color(0xFF1E88E5),
                        ),
                        _buildInfoPill(
                          icon: Icons.currency_exchange_rounded,
                          label: currency,
                          background: const Color(0xFFFFF4E8),
                          foreground: const Color(0xFFEF6C00),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onVisit,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              backgroundColor: const Color(0xFF14213D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('View Store'),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: onFollowToggle,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 13),
                              side: BorderSide(
                                color: isFollowing
                                    ? const Color(0xFFE57373)
                                    : const Color(0xFFD7DEE8),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Icon(
                              isFollowing
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFollowing
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF51606F),
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBanner(
    String name,
    List<Color> gradientColors, {
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(String name, List<Color> gradientColors) {
    return Text(
      _getInitials(name),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: gradientColors[0],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ').where((part) => part.isNotEmpty);
    final list = words.toList();
    if (list.isEmpty) return 'S';
    if (list.length == 1) return list[0][0].toUpperCase();
    return '${list[0][0]}${list[1][0]}'.toUpperCase();
  }

  String _prettyLabel(String raw) {
    return raw
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<Color> _getGradientColors(int seed) {
    final colorOptions = [
      [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      [const Color(0xFFFFBE0B), const Color(0xFFFB8500)],
      [const Color(0xFF95E1D3), const Color(0xFF38A3A5)],
      [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
      [const Color(0xFF2D9CDB), const Color(0xFF1B6CA8)],
      [const Color(0xFF00B894), const Color(0xFF00897B)],
      [const Color(0xFF5C6BC0), const Color(0xFF3949AB)],
    ];
    return colorOptions[seed.abs() % colorOptions.length];
  }
}
