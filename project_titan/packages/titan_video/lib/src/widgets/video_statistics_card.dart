import 'package:flutter/material.dart';
import '../models/video_statistics.dart';

/// Material 3 Video Statistics Card widget.
class VideoStatisticsCard extends StatelessWidget {
  final VideoStatistics statistics;

  const VideoStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              icon: Icons.remove_red_eye_rounded,
              value: '${statistics.totalViews}',
              label: 'Views',
              color: colorScheme.primary,
            ),
            _StatColumn(
              icon: Icons.percent_rounded,
              value:
                  '${statistics.completionRatePercentage.toStringAsFixed(0)}%',
              label: 'Completion',
              color: colorScheme.secondary,
            ),
            _StatColumn(
              icon: Icons.timer_rounded,
              value: '${statistics.averageWatchDurationSeconds}s',
              label: 'Avg Duration',
              color: colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
