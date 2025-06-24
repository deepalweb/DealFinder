import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DealCardShimmer extends StatelessWidget {
  const DealCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Image Placeholder
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor, // Shimmer color
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 12.0),

              // Title Placeholder
              Container(
                height: 20,
                width: double.infinity * 0.8, // 80% of width
                color: baseColor,
              ),
              const SizedBox(height: 6.0),
              Container(
                height: 18,
                width: double.infinity * 0.6, // 60% of width
                color: baseColor,
              ),
              const SizedBox(height: 8.0),

              // Merchant Name Placeholder
              Container(
                height: 16,
                width: double.infinity * 0.4, // 40% of width
                color: baseColor,
              ),
              const SizedBox(height: 8.0),

              // Description Placeholder
              Container(height: 14, width: double.infinity, color: baseColor),
              const SizedBox(height: 4.0),
              Container(height: 14, width: double.infinity, color: baseColor),
              const SizedBox(height: 4.0),
              Container(height: 14, width: double.infinity * 0.7, color: baseColor),
              const SizedBox(height: 10.0),

              // Discount and Code Row Placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 20, width: 80, color: baseColor), // Discount
                  Container(height: 20, width: 100, color: baseColor), // Code
                ],
              ),
              const SizedBox(height: 10.0),

              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 8.0),

              // Expiry Date Placeholder
              Container(
                height: 14,
                width: double.infinity * 0.5, // 50% of width
                color: baseColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper to build a list of shimmer cards
Widget buildDealsListShimmer({int itemCount = 5}) {
  return ListView.builder(
    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
    itemCount: itemCount, // Number of shimmer cards to show
    itemBuilder: (context, index) {
      return const DealCardShimmer();
    },
  );
}
