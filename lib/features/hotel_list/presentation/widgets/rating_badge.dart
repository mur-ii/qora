import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final double size;

  const RatingBadge({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.6,
        vertical: size * 0.3,
      ),
      decoration: BoxDecoration(
        color: _getRatingColor(),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: size, color: AppColors.textOnPrimary),
          SizedBox(width: size * 0.3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: size * 0.9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor() {
    if (rating >= 4.5) {
      return AppColors.success; // Green
    } else if (rating >= 4.0) {
      return AppColors.info; // Blue
    } else if (rating >= 3.5) {
      return AppColors.warning; // Orange
    } else {
      return AppColors.error; // Red
    }
  }
}
