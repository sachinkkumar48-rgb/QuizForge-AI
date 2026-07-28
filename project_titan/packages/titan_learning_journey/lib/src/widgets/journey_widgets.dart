import 'package:flutter/material.dart';
import '../models/journey_models.dart';

/// Helper to get responsive breakpoint type
enum ResponsiveBreakpoint { mobile, tablet, desktop }

ResponsiveBreakpoint getBreakpoint(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1024) return ResponsiveBreakpoint.desktop;
  if (width >= 600) return ResponsiveBreakpoint.tablet;
  return ResponsiveBreakpoint.mobile;
}

/// 1. JourneyProgressCard
class JourneyProgressCard extends StatelessWidget {
  final JourneyProgress progress;

  const JourneyProgressCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress.overallProgress * 100).toStringAsFixed(0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journey Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.overallProgress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestones: ${progress.completedMilestonesCount}/${progress.totalMilestonesCount}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Streak: ${progress.streakDays} days 🔥',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. MilestoneCard
class MilestoneCard extends StatelessWidget {
  final JourneyMilestone milestone;
  final VoidCallback? onTap;

  const MilestoneCard({
    super.key,
    required this.milestone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAchieved = milestone.status == MilestoneStatus.achieved;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAchieved
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isAchieved
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            isAchieved ? Icons.check_circle : Icons.flag_outlined,
            color: isAchieved
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          milestone.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isAchieved ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          milestone.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '${(milestone.progress * 100).toInt()}%',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// 3. AchievementCard
class AchievementCard extends StatelessWidget {
  final JourneyAchievement achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? theme.colorScheme.secondary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnlocked ? Icons.emoji_events : Icons.lock_outline,
            size: 36,
            color: isUnlocked ? Colors.amber.shade700 : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.rarity.name.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isUnlocked
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. JourneyHealthCard
class JourneyHealthCard extends StatelessWidget {
  final JourneyHealth health;

  const JourneyHealthCard({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color healthColor;
    switch (health.level) {
      case HealthLevel.excellent:
      case HealthLevel.good:
        healthColor = Colors.green;
        break;
      case HealthLevel.moderate:
        healthColor = Colors.orange;
        break;
      case HealthLevel.atRisk:
      case HealthLevel.critical:
        healthColor = Colors.red;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journey Health Score',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    health.level.name.toUpperCase(),
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: healthColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${health.score.toInt()}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / 100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: health.healthFactors
                  .map((factor) => Chip(
                        avatar:
                            const Icon(Icons.check_circle_outline, size: 14),
                        label:
                            Text(factor, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5. ForecastCard
class ForecastCard extends StatelessWidget {
  final JourneyForecast forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readinessPercent = (forecast.examReadinessProbability * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Readiness Forecast',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exam Readiness', style: theme.textTheme.bodySmall),
                    Text(
                      '$readinessPercent%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Projected Score', style: theme.textTheme.bodySmall),
                    Text(
                      '${forecast.projectedFinalScore.toInt()}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              forecast.forecastSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. JourneyInsightsCard
class JourneyInsightsCard extends StatelessWidget {
  final List<JourneyInsight> insights;

  const JourneyInsightsCard({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text('No current insights available.')
            else
              Column(
                children: insights
                    .map((insight) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            insight.type == InsightType.strength
                                ? Icons.thumb_up
                                : Icons.warning_amber,
                            color: insight.type == InsightType.strength
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: Text(
                            insight.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            insight.summary,
                            style: theme.textTheme.bodySmall,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/// 7. GoalCard
class GoalCard extends StatelessWidget {
  final JourneyGoal goal;

  const GoalCard({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.track_changes,
          color: goal.isCompleted ? Colors.green : theme.colorScheme.primary,
        ),
        title: Text(
          goal.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Target Score: ${goal.targetScore}% • ${goal.difficulty.name}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          goal.isCompleted ? Icons.check_circle : Icons.hourglass_top,
          color: goal.isCompleted ? Colors.green : theme.colorScheme.outline,
        ),
      ),
    );
  }
}

/// 8. CheckpointCard
class CheckpointCard extends StatelessWidget {
  final JourneyCheckpoint checkpoint;
  final VoidCallback? onEvaluate;

  const CheckpointCard({
    super.key,
    required this.checkpoint,
    this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassed = checkpoint.status == CheckpointStatus.passed;

    return Card(
      color: isPassed
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isPassed ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isPassed ? Icons.verified : Icons.lock_clock,
          color: isPassed ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          checkpoint.title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Required Score: ${checkpoint.requiredScore}% | Status: ${checkpoint.status.name}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: onEvaluate != null
            ? ElevatedButton(
                onPressed: onEvaluate,
                child: const Text('Evaluate'),
              )
            : null,
      ),
    );
  }
}

/// 9. JourneyRecommendationPanel
class JourneyRecommendationPanel extends StatelessWidget {
  final List<JourneyRecommendation> recommendations;
  final ValueChanged<JourneyRecommendation>? onActionSelected;

  const JourneyRecommendationPanel({
    super.key,
    required this.recommendations,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Recommended Next Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: recommendations
                  .map((rec) => Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            rec.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            rec.rationale,
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: FilledButton.tonal(
                            onPressed: onActionSelected != null
                                ? () => onActionSelected!(rec)
                                : null,
                            child: const Text('Start'),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 10. JourneyTimelineWidget
class JourneyTimelineWidget extends StatelessWidget {
  final JourneyTimeline timeline;

  const JourneyTimelineWidget({
    super.key,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey Timeline',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timeline.events.length,
          itemBuilder: (context, index) {
            final event = timeline.events[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    if (index < timeline.events.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: theme.colorScheme.outlineVariant,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event.description,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 11. LearningRoadmapWidget
class LearningRoadmapWidget extends StatelessWidget {
  final List<JourneyStage> stages;
  final ValueChanged<JourneyMilestone>? onMilestoneTap;

  const LearningRoadmapWidget({
    super.key,
    required this.stages,
    this.onMilestoneTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: stages.map((stage) {
        final isInProgress = stage.status == JourneyStageStatus.inProgress;
        final isCompleted = stage.status == JourneyStageStatus.completed;

        return Card(
          elevation: isInProgress ? 3 : 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isInProgress
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isInProgress ? 2 : 1,
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: isInProgress,
            leading: CircleAvatar(
              backgroundColor: isCompleted
                  ? Colors.green
                  : isInProgress
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                '${stage.orderIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              stage.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${stage.description} • ${(stage.progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    ...stage.milestones.map((ms) => MilestoneCard(
                          milestone: ms,
                          onTap: onMilestoneTap != null
                              ? () => onMilestoneTap!(ms)
                              : null,
                        )),
                    if (stage.checkpoint != null) ...[
                      const SizedBox(height: 8),
                      CheckpointCard(checkpoint: stage.checkpoint!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 12. JourneyDashboard (Responsive Container)
class JourneyDashboard extends StatelessWidget {
  final LearningJourney journey;
  final List<JourneyRecommendation> recommendations;
  final List<JourneyInsight> insights;
  final JourneyTimeline timeline;
  final ValueChanged<JourneyMilestone>? onMilestoneTap;

  const JourneyDashboard({
    super.key,
    required this.journey,
    required this.recommendations,
    required this.insights,
    required this.timeline,
    this.onMilestoneTap,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = getBreakpoint(context);

    if (breakpoint == ResponsiveBreakpoint.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  JourneyProgressCard(progress: journey.progress),
                  const SizedBox(height: 16),
                  LearningRoadmapWidget(
                    stages: journey.stages,
                    onMilestoneTap: onMilestoneTap,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  JourneyHealthCard(health: journey.health),
                  const SizedBox(height: 16),
                  ForecastCard(forecast: journey.forecast),
                  const SizedBox(height: 16),
                  JourneyRecommendationPanel(recommendations: recommendations),
                  const SizedBox(height: 16),
                  JourneyInsightsCard(insights: insights),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          JourneyProgressCard(progress: journey.progress),
          const SizedBox(height: 16),
          JourneyHealthCard(health: journey.health),
          const SizedBox(height: 16),
          ForecastCard(forecast: journey.forecast),
          const SizedBox(height: 16),
          JourneyRecommendationPanel(recommendations: recommendations),
          const SizedBox(height: 16),
          LearningRoadmapWidget(
            stages: journey.stages,
            onMilestoneTap: onMilestoneTap,
          ),
          const SizedBox(height: 16),
          JourneyInsightsCard(insights: insights),
        ],
      ),
    );
  }
}
