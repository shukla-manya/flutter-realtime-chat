import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'ms_mark.dart';

class BrandFooter extends StatelessWidget {
  const BrandFooter({
    super.key,
    this.light = false,
  });

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.textSecondary.withValues(alpha: 0.95);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MsMark(size: 16, showGlow: true),
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
      ),
    );
  }
}
