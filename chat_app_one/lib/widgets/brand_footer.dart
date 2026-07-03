import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'ms_mark.dart';

class BrandFooter extends StatelessWidget {
  const BrandFooter({
    super.key,
    this.light = false,
  });

  final bool light;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = light
        ? Colors.white.withValues(alpha: 0.82)
        : isDark
            ? Colors.white.withValues(alpha: 0.45)
            : AppColors.textMuted.withValues(alpha: 0.9);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MsMark(size: 16, showGlow: light),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppConstants.footerText,
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
