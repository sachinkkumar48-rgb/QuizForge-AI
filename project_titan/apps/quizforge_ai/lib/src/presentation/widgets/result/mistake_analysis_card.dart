import 'package:flutter/material.dart';
import 'package:titan_analytics/titan_analytics.dart';

/// Reusable Material 3 widget analyzing categorized errors and diagnostic insights.
class MistakeAnalysisCard extends StatelessWidget {
  final MistakeAnalysis mistakeAnalysis;

  const MistakeAnalysisCard({
    super.key,
    required this.mistakeAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: colorScheme.error,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mistake Taxonomy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  context,
                  label: 'Conceptual: ${mistakeAnalysis.conceptualErrors}',
                  color: Colors.deepOrange,
                ),
                _buildChip(
                  context,
                  label: 'Silly Errors: ${mistakeAnalysis.sillyErrors}',
                  color: Colors.amber.shade800,
                ),
                _buildChip(
                  context,
                  label: 'Time Pressure: ${mistakeAnalysis.timePressureErrors}',
                  color: Colors.purple,
                ),
                _buildChip(
                  context,
                  label: 'Skipped: ${mistakeAnalysis.skippedCount}',
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Diagnostic Insights',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...mistakeAnalysis.keyMistakeInsights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context,
      {required String label, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
