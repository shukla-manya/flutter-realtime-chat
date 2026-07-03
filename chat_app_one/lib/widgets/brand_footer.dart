import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'ms_mark.dart';

class BrandFooter extends StatelessWidget {
  const BrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textMuted.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MsMark(size: 16),
          const SizedBox(width: 8),
          Text(
            'by MANYA SHUKLA 2026',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
