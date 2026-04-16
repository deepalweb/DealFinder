import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/category_icon.dart';

class MerchantCard extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final VoidCallback onVisit;
  final VoidCallback onFollowToggle;
  final bool isFollowing;
  final VoidCallback onShare;

  const MerchantCard({
    super.key,
    required this.merchant,
    required this.onVisit,
    required this.onFollowToggle,
    required this.isFollowing,
    required this.onShare,
  });

  Widget _buildImageWidget(String? imageUrl, Widget placeholder, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;
    
    // Handle base64 data URI
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
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
    
    // Handle HTTP/HTTPS URL
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
    final name = merchant['name'] ?? 'Unnamed Store';
    final category = merchant['category'] ?? 'other';
    final followers = merchant['followers'] ?? 0;
    final deals = merchant['activeDeals'] ?? merchant['deals'] ?? 0;
    final currency = merchant['currency'] ?? 'LKR';
    final logoUrl = merchant['logo'];
    final bannerUrl = merchant['banner'];
    
    final hasLogo = logoUrl != null && logoUrl.toString().isNotEmpty;
    final hasBanner = bannerUrl != null && bannerUrl.toString().isNotEmpty;
    final colorSeed = name.hashCode;
    final gradientColors = _getGradientColors(colorSeed);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: onVisit,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Banner - either image or gradient
                hasBanner
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: _buildImageWidget(
                          bannerUrl,
                          _buildGradientBanner(name, gradientColors),
                          height: 140,
                          width: double.infinity,
                        ),
                      )
                    : _buildGradientBanner(name, gradientColors),
                // Logo Circle
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: hasLogo
                          ? ClipOval(
                              child: _buildImageWidget(
                                logoUrl,
                                _buildLogoPlaceholder(name, gradientColors),
                                width: 64,
                                height: 64,
                              ),
                            )
                          : _buildLogoPlaceholder(name, gradientColors),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                CategoryIcon(category: category, size: 18),
                              ],
                            ),
                            if (merchant['description'] != null && merchant['description'].toString().isNotEmpty)
                              const SizedBox(height: 6),
                            if (merchant['description'] != null && merchant['description'].toString().isNotEmpty)
                              Text(
                                merchant['description'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              isFollowing ? Icons.favorite : Icons.favorite_border,
                              color: isFollowing ? Colors.red : Colors.grey[600],
                            ),
                            tooltip: isFollowing ? 'Unfollow' : 'Follow',
                            onPressed: onFollowToggle,
                          ),
                          IconButton(
                            icon: Icon(Icons.share, color: Colors.grey[600]),
                            tooltip: 'Share',
                            onPressed: onShare,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[700]),
                            const SizedBox(width: 4),
                            Text(
                              '$followers',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '$deals deals',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 2),
                            Text(
                              currency,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBanner(String name, List<Color> gradientColors) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            fontSize: 48,
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
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'S';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  List<Color> _getGradientColors(int seed) {
    final colorOptions = [
      [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      [const Color(0xFFFFBE0B), const Color(0xFFFB8500)],
      [const Color(0xFF95E1D3), const Color(0xFF38A3A5)],
      [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      [const Color(0xFF3498DB), const Color(0xFF2980B9)],
      [const Color(0xFFFF6B9D), const Color(0xFFC06C84)],
      [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
    ];
    return colorOptions[seed.abs() % colorOptions.length];
  }
}
