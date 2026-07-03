import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SmartReplyChips extends StatelessWidget {
  const SmartReplyChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.35),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          onPressed: () => onSelected(suggestion),
        );
      }).toList(),
    );
  }
}
