import 'package:flutter/material.dart';

import '../../controllers/dashboard_state.dart';

/// Stat Summary Cards component displaying core metrics in a responsive grid.
class StatSummaryCardWidget extends StatelessWidget {
  final DashboardStats stats;

  const StatSummaryCardWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 550
                ? 2
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 550 ? 1.8 : 1.6,
          children: [
            _buildMetricCard(
              context: context,
              icon: Icons.quiz,
              label: "Quizzes Completed",
              value: "${stats.totalQuizzesCompleted}",
              color: Colors.deepPurple,
            ),
            _buildMetricCard(
              context: context,
              icon: Icons.pie_chart,
              label: "Avg. Accuracy",
              value: "${stats.averageAccuracyPercentage.toStringAsFixed(1)}%",
              color: Colors.green,
            ),
            _buildMetricCard(
              context: context,
              icon: Icons.check_circle_outline,
              label: "Questions Solved",
              value: "${stats.totalQuestionsAnswered}",
              color: Colors.blue,
            ),
            _buildMetricCard(
              context: context,
              icon: Icons.picture_as_pdf,
              label: "PDF Sources",
              value: "${stats.totalPdfSources}",
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
