import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final bool allowHalfRating;

  const RatingWidget({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        double starRating = rating - index;

        if (starRating >= 1) {
          return Icon(Icons.star, size: size, color: color);
        } else if (starRating >= 0.5 && allowHalfRating) {
          return Icon(Icons.star_half, size: size, color: color);
        } else {
          return Icon(Icons.star_border, size: size, color: color);
        }
      }),
    );
  }
}

class InteractiveRatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final int starCount;
  final double size;
  final Color color;
  final bool enabled;

  const InteractiveRatingWidget({
    super.key,
    required this.onRatingChanged,
    this.initialRating = 0,
    this.starCount = 5,
    this.size = 30,
    this.color = Colors.amber,
    this.enabled = true,
  });

  @override
  State<InteractiveRatingWidget> createState() =>
      _InteractiveRatingWidgetState();
}

class _InteractiveRatingWidgetState extends State<InteractiveRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(covariant InteractiveRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        return GestureDetector(
          onTap: () {
            if (!widget.enabled) return;
            setState(() {
              _currentRating = index + 1.0;
            });
            widget.onRatingChanged(_currentRating);
          },
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: widget.color,
          ),
        );
      }),
    );
  }
}
