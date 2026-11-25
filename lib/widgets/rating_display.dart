import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final num rating;
  final double size;
  final Color color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < filled ? Icons.star_rounded : Icons.star_border_rounded,
          color: color,
          size: size,
        ),
      ),
    );
  }
}

class RatingSummaryLink extends StatelessWidget {
  final num rating;
  final num count;
  final VoidCallback? onTap;
  final Color textColor;

  const RatingSummaryLink({
    super.key,
    required this.rating,
    required this.count,
    this.onTap,
    this.textColor = const Color(0xff475569),
  });

  @override
  Widget build(BuildContext context) {
    final hasReviews = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 19, color: Colors.amber),
            const SizedBox(width: 3),
            Text(
              hasReviews ? rating.toStringAsFixed(1) : "New",
              style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(width: 4),
            Text(
              hasReviews
                  ? "($count ${count == 1 ? 'review' : 'reviews'})"
                  : "No reviews yet",
              style: TextStyle(fontSize: 12, color: textColor),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 3),
              Icon(Icons.chevron_right, size: 17, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}
