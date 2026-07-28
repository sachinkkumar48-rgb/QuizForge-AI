import 'package:flutter/material.dart';

import '../orchestrator/unified_dashboard_state.dart';

/// Section 8: Assessment Readiness Card.
/// Displays readiness score gauge/indicator, weakest subject, and strongest subject. Reuses titan_smart_assessment.
class AssessmentCard extends StatelessWidget {
  final AssessmentReadinessData data;
  final VoidCallback? onTakeAssessmentTap;

  const AssessmentCard({
    super.key,
    required this.data,
    this.onTakeAssessmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color scoreColor;
    if (data.readinessScore >= 80) {
      scoreColor = Colors.green;
    } else if (data.readinessScore >= 60) {
      scoreColor = Colors.amber.shade800;
    } else {
      scoreColor = colorScheme.error;
    }

    return Semantics(
      label: 'Assessment Readiness Score Card',
      container: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.quiz_rounded,
                            color: colorScheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ASSESSMENT READINESS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.readinessLevel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Gauge / Score Box
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scoreColor, width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${data.readinessScore}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          'SCORE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubjectRow(
                          context,
                          label: 'Strongest:',
                          subject: data.strongestSubject,
                          icon: Icons.thumb_up_alt_rounded,
                          iconColor: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildSubjectRow(
                          context,
                          label: 'Weakest:',
                          subject: data.weakestSubject,
                          icon: Icons.warning_amber_rounded,
                          iconColor: colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onTakeAssessmentTap,
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: const Text('Take Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(
    BuildContext context, {
    required String label,
    required String subject,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            subject,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
