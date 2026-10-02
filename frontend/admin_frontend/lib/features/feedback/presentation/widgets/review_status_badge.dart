import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../data/models/product_review_model.dart';

class ReviewStatusBadge extends StatelessWidget {
  final ReviewVisibility visibility;
  const ReviewStatusBadge({super.key, required this.visibility});
  @override
  Widget build(BuildContext context) {
    final color = visibility == ReviewVisibility.visible
        ? AppTheme.success
        : AppTheme.textSecondary;
    return StatusBadge(
      text: visibility.label,
      textColor: color,
      backgroundColor: color.withAlpha(25),
    );
  }
}

class ReviewStars extends StatelessWidget {
  final int rating;
  const ReviewStars({super.key, required this.rating});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$rating trên 5 sao',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 18,
            color: Colors.amber.shade700,
          ),
        const SizedBox(width: 6),
        Text('$rating/5'),
      ],
    ),
  );
}
