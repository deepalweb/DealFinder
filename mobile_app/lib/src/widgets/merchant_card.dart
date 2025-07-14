import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final bannerUrl = merchant['banner'] ?? merchant['logo'];
    final name = merchant['name'] ?? 'Unnamed Store';
    final category = merchant['category'] ?? 'Other';
    final followers = merchant['followers'] ?? 0;
    final deals = merchant['activeDeals'] ?? merchant['deals'] ?? 0;
    final isBanner = bannerUrl != null && bannerUrl.toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBanner)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                bannerUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.store, size: 40, color: Colors.white),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(merchant['logo'] ?? ''),
                  backgroundColor: Colors.grey[200],
                  child: merchant['logo'] == null ? const Icon(Icons.store, size: 32) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          CategoryIcon(category: category, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        merchant['description'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('$followers followers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 12),
                          Icon(Icons.local_offer, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('$deals deals', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(isFollowing ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      tooltip: isFollowing ? 'Unfollow' : 'Follow',
                      onPressed: onFollowToggle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      tooltip: 'Share',
                      onPressed: onShare,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: onVisit,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size.fromHeight(36),
              ),
              child: const Text('Visit Store'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
