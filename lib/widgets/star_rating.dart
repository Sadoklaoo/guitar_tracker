// lib/widgets/star_rating.dart

import 'package:flutter/material.dart';
import '../config/theme.dart';

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const StarRatingDisplay({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppTheme.amber, size: size),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.amber,
                fontWeight: FontWeight.w600,
                fontSize: size - 2,
              ),
        ),
      ],
    );
  }
}

class StarRatingSelector extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;

  const StarRatingSelector({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
  });

  @override
  State<StarRatingSelector> createState() => _StarRatingSelectorState();
}

class _StarRatingSelectorState extends State<StarRatingSelector> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = (index + 1).toDouble();
        return GestureDetector(
          onTap: () {
            setState(() => _rating = starValue);
            widget.onRatingChanged(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              _rating >= starValue
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: AppTheme.amber,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}
