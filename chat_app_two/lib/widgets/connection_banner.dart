import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/connection_status.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == ConnectionStatus.connected ||
        status == ConnectionStatus.disconnected) {
      return const SizedBox.shrink();
    }

    final isError = status == ConnectionStatus.error;
    final color = isError ? AppColors.error : AppColors.warning;
    final text = isError
        ? 'Connection lost'
        : status == ConnectionStatus.reconnecting
            ? 'Reconnecting…'
            : 'Connecting…';

    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isError ? Icons.wifi_off_rounded : Icons.sync_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (!isError)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
