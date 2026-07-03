import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: AppColors.cyan,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send the first message in #$roomId.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
