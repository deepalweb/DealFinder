import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MerchantCardShimmer extends StatelessWidget {
  const MerchantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 18, width: 120, color: baseColor),
                        const SizedBox(height: 8),
                        Container(height: 14, width: 180, color: baseColor),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(height: 12, width: 60, color: baseColor),
                            const SizedBox(width: 12),
                            Container(height: 12, width: 60, color: baseColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(height: 32, width: 32, color: baseColor),
                      const SizedBox(height: 8),
                      Container(height: 32, width: 32, color: baseColor),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(height: 36, width: double.infinity, color: baseColor),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

Widget buildMerchantListShimmer({int itemCount = 5}) {
  return ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: itemCount,
    itemBuilder: (context, index) => const MerchantCardShimmer(),
  );
}
