import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final bool isPromo;
  final double fontSize;

  const PriceTag({
    super.key,
    required this.price,
    this.isPromo = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPromo)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.discount,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PROMO',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: fontSize * 0.55,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              formatter.format(price),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Text(
          '/ night',
          style: TextStyle(
            fontSize: fontSize * 0.7,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
