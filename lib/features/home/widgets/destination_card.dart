import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Legacy destination card — use _DestinationCard inside destination_section.dart instead.
@Deprecated('Use DestinationSection inline card')
class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}
