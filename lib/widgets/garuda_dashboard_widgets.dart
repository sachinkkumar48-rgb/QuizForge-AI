import 'package:flutter/material.dart';
import 'package:quizforge_upsc/controllers/garuda_dashboard_viewmodel.dart';

/// 1. OverviewCard Widget
class OverviewCard extends StatelessWidget {
  final DashboardSummaryDto summary;

  const OverviewCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Learning Overview Summary Card',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Learning Overview',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildStatTile(
                      theme,
                      'Mastery',
                      '${(summary.overallMastery * 100).toStringAsFixed(0)}%',
                      Colors.blue),
                  _buildStatTile(
                      theme,
                      'Accuracy',
                      '${(summary.overallAccuracy * 100).toStringAsFixed(0)}%',
                      Colors.green),
                  _buildStatTile(theme, 'Attempted',
                      '${summary.questionsAttempted}', Colors.orange),
                  _buildStatTile(theme, 'Correct', '${summary.correctAnswers}',
                      Colors.teal),
                  _buildStatTile(
                      theme, 'Hours', '${summary.studyHours}h', Colors.purple),
                  _buildStatTile(theme, 'Streak', '${summary.studyStreak}d 🔥',
                      Colors.deepOrange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
      ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// 2. MasteryCard Widget
class MasteryCard extends StatelessWidget {
  final double mastery;
  final String currentTopic;

  const MasteryCard(
      {super.key, required this.mastery, required this.currentTopic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pct = (mastery * 100).round();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: mastery,
                    strokeWidth: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Text('$pct%',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall Topic Mastery',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(currentTopic,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. AccuracyCard Widget
class AccuracyCard extends StatelessWidget {
  final PerformanceAnalyticsDto performance;

  const AccuracyCard({super.key, required this.performance});

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
            Text('Accuracy Trends',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAccuracyCol(theme, 'Daily', performance.dailyAccuracy),
                _buildAccuracyCol(theme, 'Weekly', performance.weeklyAccuracy),
                _buildAccuracyCol(
                    theme, 'Monthly', performance.monthlyAccuracy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCol(ThemeData theme, String label, double value) {
    return Column(
      children: [
        Text('${(value * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// 4. StudyStreakCard Widget
class StudyStreakCard extends StatelessWidget {
  final int streakDays;

  const StudyStreakCard({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streakDays Day Study Streak!',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer)),
                  Text('Keep up the momentum to build long-term memory.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5. TopicHeatmap Widget
class TopicHeatmap extends StatelessWidget {
  final TopicAnalyticsDto topicAnalytics;

  const TopicHeatmap({super.key, required this.topicAnalytics});

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
            Text('Topic Mastery Heatmap',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...topicAnalytics.strongTopics.map((t) => Chip(
                      label: Text(t),
                      backgroundColor: Colors.green.shade100,
                      avatar: const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                    )),
                ...topicAnalytics.weakTopics.map((t) => Chip(
                      label: Text(t),
                      backgroundColor: Colors.red.shade100,
                      avatar: const Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 16),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. ProgressChart Widget
class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mastery Progress Trend',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [40, 55, 62, 58, 70, 78, 85].map((val) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 16,
                        height: val.toDouble(),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('$val%', style: const TextStyle(fontSize: 10)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 7. RevisionCard Widget
class RevisionCard extends StatelessWidget {
  final RevisionAnalyticsDto revision;

  const RevisionCard({super.key, required this.revision});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Icon(Icons.style_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Spaced Repetition Queue',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
                value: revision.completionPct / 100,
                backgroundColor: colorScheme.surfaceContainerHighest),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completed: ${revision.completed}/${revision.todaysQueue}',
                    style: theme.textTheme.labelMedium),
                Text('Ease: ${revision.avgEaseFactor}',
                    style: theme.textTheme.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. RecommendationCard Widget
class RecommendationCard extends StatelessWidget {
  final RecommendationsDto recs;
  final VoidCallback? onStartRemedial;

  const RecommendationCard({
    super.key,
    required this.recs,
    this.onStartRemedial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRemedial = onStartRemedial != null;

    return Card(
      elevation: 3,
      color: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text('Next Best Action',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer)),
              ],
            ),
            const SizedBox(height: 8),
            Text(recs.nextBestAction,
                style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onTertiaryContainer)),
            const SizedBox(height: 4),
            Text('Goal: ${recs.todaysGoal}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onTertiaryContainer)),
            if (isRemedial) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onStartRemedial,
                icon: const Icon(Icons.healing_rounded),
                label: const Text('Start Remedial Practice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 9. PlannerCard Widget
class PlannerCard extends StatelessWidget {
  final StudyAnalyticsDto study;

  const PlannerCard({super.key, required this.study});

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
            Text('Today\'s Study Plan',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...study.todaysPlan.map((task) => ListTile(
                  dense: true,
                  leading: Icon(
                    task['completed'] == true
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color:
                        task['completed'] == true ? Colors.green : Colors.grey,
                  ),
                  title: Text(task['title'] ?? ''),
                  subtitle: Text('${task['type']} • ${task['duration']} mins'),
                )),
          ],
        ),
      ),
    );
  }
}

/// 10. WeeklyProgressCard Widget
class WeeklyProgressCard extends StatelessWidget {
  final double weeklyProgress;

  const WeeklyProgressCard({super.key, required this.weeklyProgress});

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
            Text('Weekly Target Progress',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: weeklyProgress / 100.0),
            const SizedBox(height: 4),
            Text(
                '${weeklyProgress.toStringAsFixed(0)}% of weekly study target completed',
                style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// 11. MonthlyProgressCard Widget
class MonthlyProgressCard extends StatelessWidget {
  final double monthlyProgress;

  const MonthlyProgressCard({super.key, required this.monthlyProgress});

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
            Text('Monthly Syllabus Completion',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: monthlyProgress / 100.0, color: Colors.purple),
            const SizedBox(height: 4),
            Text(
                '${monthlyProgress.toStringAsFixed(0)}% overall monthly target achieved',
                style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility widgets
class NextBestActionCard extends StatelessWidget {
  final NextBestActionDto? nba;
  final VoidCallback? onStartRemedial;

  const NextBestActionCard({super.key, this.nba, this.onStartRemedial});

  @override
  Widget build(BuildContext context) {
    final hasRemedial = nba?.recType == 'remedial' ||
        nba?.recType == 'WEAK_TOPIC_REVISION' ||
        nba?.recType == 'remediation' ||
        (nba?.title.toLowerCase().contains('remedial') ?? false);

    return RecommendationCard(
      recs: RecommendationsDto(
        nextBestAction: nba?.title ?? 'Revise Article 21 Rights',
        todaysGoal: 'Achieve 80%+ Accuracy',
        priorityTopic: 'Polity',
        suggestedRevision: 'Revision Queue',
        suggestedQuiz: '10 Questions Quiz',
        suggestedReading: 'Summary PDF',
      ),
      onStartRemedial: hasRemedial ? onStartRemedial : null,
    );
  }
}

class TodayStudyPlanCard extends StatelessWidget {
  final DailyStudyPlanDto? plan;
  const TodayStudyPlanCard({super.key, this.plan});
  @override
  Widget build(BuildContext context) {
    return PlannerCard(
      study: StudyAnalyticsDto(
        todaysPlan: const [
          {
            'title': 'Revise Article 21 Rights',
            'type': 'revision',
            'duration': 30,
            'completed': true
          },
        ],
        completedTasks: 1,
        remainingTasks: 1,
        weeklyProgress: 75.0,
        monthlyProgress: 68.0,
        studyTimeMinutes: plan?.totalStudyMinutes ?? 120,
        completionPct: 50.0,
      ),
    );
  }
}

class TodayRevisionQueueCard extends StatelessWidget {
  final RevisionQueueDto? queue;
  const TodayRevisionQueueCard({super.key, this.queue});
  @override
  Widget build(BuildContext context) {
    return RevisionCard(
      revision: RevisionAnalyticsDto(
        todaysQueue: queue?.queueSize ?? 12,
        completed: 7,
        pending: queue?.totalDueItems ?? 5,
        overdue: queue?.urgentItemsCount ?? 2,
        avgEaseFactor: 2.5,
        avgInterval: 3.0,
        nextRevision: 'Today 6:00 PM',
        completionPct: 58.3,
      ),
    );
  }
}

class LearningProgressCard extends StatelessWidget {
  final LearningProfileDto? profile;
  const LearningProgressCard({super.key, this.profile});
  @override
  Widget build(BuildContext context) {
    return MasteryCard(
      mastery: profile?.overallMastery ?? 0.68,
      currentTopic: profile?.currentTopic ?? 'Indian Polity',
    );
  }
}

class RecentConversationsCard extends StatelessWidget {
  final List<RecentConversationDto> conversations;
  const RecentConversationsCard({super.key, required this.conversations});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Tutor Sessions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            ...conversations.map((c) => ListTile(
                  title: Text(c.topicName),
                  subtitle: Text(c.lastMessage),
                  dense: true,
                )),
          ],
        ),
      ),
    );
  }
}

class PdfLibraryCard extends StatelessWidget {
  final List<UploadedPdfDto> pdfs;
  const PdfLibraryCard({super.key, required this.pdfs});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF Knowledge Library',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            ...pdfs.map((p) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.red),
                  title: Text(p.documentName),
                  subtitle: Text('${p.chunksCount} chunks indexed'),
                  dense: true,
                )),
          ],
        ),
      ),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  final ValueChanged<String> onActionSelected;
  final bool hasRemedialTarget;

  const QuickActionsCard({
    super.key,
    required this.onActionSelected,
    this.hasRemedialTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasRemedialTarget)
                  ActionChip(
                    avatar: const Icon(Icons.healing_rounded, size: 16),
                    label: const Text('Start Remedial Practice'),
                    onPressed: () => onActionSelected('remedial_practice'),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text('Ask GARUDA AI'),
                  onPressed: () => onActionSelected('chat'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.style_rounded, size: 16),
                  label: const Text('Flashcards'),
                  onPressed: () => onActionSelected('flashcards'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
