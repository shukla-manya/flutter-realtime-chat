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
        ? 'Connection lost. Check the server and try rejoining.'
        : status == ConnectionStatus.reconnecting
            ? 'Reconnecting to chat…'
            : 'Connecting…';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.15),
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
        ],
      ),
    );
  }
}
