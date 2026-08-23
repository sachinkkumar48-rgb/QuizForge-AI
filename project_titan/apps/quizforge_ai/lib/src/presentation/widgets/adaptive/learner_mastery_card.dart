import 'package:flutter/material.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import '../../theme/app_spacing.dart';

/// Card widget rendering learner profile mastery metrics, accuracy breakdown, and topic trends.
class LearnerMasteryCard extends StatelessWidget {
  final LearnerProfile profile;
  final ValueChanged<String>? onTopicSelected;

  const LearnerMasteryCard({
    super.key,
    required this.profile,
    this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (profile.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learner Mastery Profile',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Complete your first assessment to unlock mastery tracking, weak-area detection, and difficulty adaptation.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Knowledge & Mastery Profile',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${(profile.overallMastery * 100).toStringAsFixed(0)}% Mastery',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: profile.overallMastery,
                minHeight: 10,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  profile.overallMastery >= 0.75
                      ? Colors.green
                      : profile.overallMastery < 0.50
                          ? Colors.orange
                          : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    context, 'Assessments', '${profile.totalAssessments}'),
                _buildStatItem(
                    context, 'Questions', '${profile.totalQuestionsAttempted}'),
                _buildStatItem(
                  context,
                  'Accuracy',
                  '${(profile.overallAccuracy * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            if (profile.topicPerformance.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Topic Proficiency',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...profile.topicPerformance.values
                  .map((topic) => _buildTopicRow(context, topic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicRow(BuildContext context, TopicMastery topic) {
    final theme = Theme.of(context);

    final IconData trendIcon;
    final Color trendColor;
    switch (topic.trend) {
      case MasteryTrend.improving:
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        break;
      case MasteryTrend.declining:
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        break;
      case MasteryTrend.stable:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
        break;
      case MasteryTrend.insufficientData:
        trendIcon = Icons.remove;
        trendColor = Colors.grey;
        break;
    }

    return InkWell(
      onTap:
          onTopicSelected != null ? () => onTopicSelected!(topic.topic) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          topic.topic,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (topic.isWeak) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'WEAK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ] else if (topic.isStrong) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'MASTERED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(trendIcon, size: 16, color: trendColor),
                const SizedBox(width: 6),
                Text(
                  '${(topic.masteryScore * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: topic.masteryScore,
                minHeight: 6,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  topic.isWeak
                      ? Colors.red.shade400
                      : topic.isStrong
                          ? Colors.green.shade500
                          : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
