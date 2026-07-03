import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class MsMark extends StatelessWidget {
  const MsMark({
    super.key,
    this.size = 48,
    this.showGlow = false,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        'MS',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          letterSpacing: size * 0.02,
          height: 1,
        ),
      ),
    );
  }
}
