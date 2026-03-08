import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final double fontSize;

  const PriceTag({super.key, required this.price, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: formatter.format(price),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          TextSpan(
            text: ' /malam',
            style: TextStyle(
              fontSize: fontSize * 0.72,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
