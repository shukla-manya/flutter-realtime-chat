import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: AppLayout.bubbleMaxWidth(context),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: isDark ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    final time = DateFormat.jm().format(message.timestamp.toLocal());

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.bubbleMaxWidth(context),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: isMine ? AppColors.primaryGradient : null,
            color: isMine
                ? null
                : (isDark ? AppColors.darkSurface : AppColors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        message.sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                    if (message.isAi) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (!isMine) const SizedBox(height: 3),
              SelectableText(
                message.content,
                style: TextStyle(
                  color: isMine
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textDark),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.8)
                      : (isDark ? Colors.white54 : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
