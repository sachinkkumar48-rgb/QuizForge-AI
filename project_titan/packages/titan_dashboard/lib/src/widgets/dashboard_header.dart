import 'package:flutter/material.dart';

import '../models/dashboard_snapshot.dart';

/// Material 3 header widget displaying learner greeting, target exam, and refresh button.
class DashboardHeader extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final VoidCallback? onRefresh;

  const DashboardHeader({
    super.key,
    required this.snapshot,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.0,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.analytics_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${snapshot.userName} 👋',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Target: ${snapshot.targetExam} • Readiness: ${snapshot.readinessScore}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRefresh,
              tooltip: 'Refresh Dashboard',
            ),
        ],
      ),
    );
  }
}
