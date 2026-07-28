import 'package:flutter/material.dart';

/// Banner notifying learner when the dashboard is running offline with cached data.
class DashboardOfflineBanner extends StatelessWidget {
  final DateTime lastUpdated;

  const DashboardOfflineBanner({
    super.key,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formattedTime =
        '${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'Offline Mode — Cached as of $formattedTime',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
