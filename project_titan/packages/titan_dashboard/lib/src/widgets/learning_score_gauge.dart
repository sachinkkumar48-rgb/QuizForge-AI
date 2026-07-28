import 'package:flutter/material.dart';

/// Material 3 circular gauge visualizing readiness score (0 - 100%).
class LearningScoreGauge extends StatelessWidget {
  final double readinessScore;
  final String label;

  const LearningScoreGauge({
    super.key,
    required this.readinessScore,
    this.label = 'UPSC Readiness',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalizedScore = (readinessScore / 100.0).clamp(0.0, 1.0);

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90.0,
                  height: 90.0,
                  child: CircularProgressIndicator(
                    value: normalizedScore,
                    strokeWidth: 10.0,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: readinessScore >= 75.0
                        ? Colors.green
                        : readinessScore >= 50.0
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${readinessScore.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Score',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
