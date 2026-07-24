import 'package:flutter/material.dart';

import '../../models/pyq_analytics_model.dart';

/// Professional Streak Header Card displaying Daily and Weekly Streaks
class StreakHeaderCard extends StatelessWidget {
  final StreakMetrics streakMetrics;

  const StreakHeaderCard({super.key, required this.streakMetrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Daily Streak Badge
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.deepOrange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${streakMetrics.currentDailyStreak} Days",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Daily Streak (Max ${streakMetrics.maxDailyStreak})",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            // Weekly Streak Badge
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${streakMetrics.currentWeeklyStreak} Wks",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Weekly Streak",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4-KPI Overview Grid: Accuracy, Speed, Consistency, Retention
class KpiOverviewGrid extends StatelessWidget {
  final PyqAnalyticsModel analytics;

  const KpiOverviewGrid({super.key, required this.analytics});

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTile(
                context,
                title: "Overall Accuracy",
                value:
                    "${analytics.overallAccuracyPercent.toStringAsFixed(1)}%",
                subtitle:
                    "${analytics.totalCorrect} / ${analytics.totalAttempted} Correct",
                icon: Icons.track_changes,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTile(
                context,
                title: "Solving Speed",
                value:
                    "${analytics.speedMetrics.avgSecondsPerQuestion.toStringAsFixed(0)}s/Q",
                subtitle: "Pace: ${analytics.speedMetrics.speedStatus}",
                icon: Icons.speed,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTile(
                context,
                title: "Consistency",
                value:
                    "${analytics.consistencyMetrics.consistencyScorePercent.toStringAsFixed(0)}%",
                subtitle:
                    "${analytics.consistencyMetrics.totalActiveDays} Days Active",
                icon: Icons.date_range,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTile(
                context,
                title: "Memory Retention",
                value:
                    "${analytics.retentionMetrics.retentionPercent.toStringAsFixed(1)}%",
                subtitle:
                    "${analytics.retentionMetrics.repeatCorrectCount} / ${analytics.retentionMetrics.repeatAttemptCount} Repeated",
                icon: Icons.psychology,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Strengths & Weaknesses Panel Card
class StrengthsWeaknessesCard extends StatelessWidget {
  final List<String> weakSubjects;
  final List<String> strongSubjects;

  const StrengthsWeaknessesCard({
    super.key,
    required this.weakSubjects,
    required this.strongSubjects,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (weakSubjects.isEmpty && strongSubjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performance Spectrum",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (weakSubjects.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "Focus Areas (< 50% Accuracy):",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: weakSubjects.map((sub) {
                  return Chip(
                    avatar:
                        const Icon(Icons.close, color: Colors.red, size: 14),
                    label: Text(sub),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
            if (strongSubjects.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "Strong Mastery (>= 70% Accuracy):",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: strongSubjects.map((sub) {
                  return Chip(
                    avatar:
                        const Icon(Icons.check, color: Colors.green, size: 14),
                    label: Text(sub),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Interactive Segmented Trend Analysis Component (Subject, Topic, Year, Difficulty)
class TrendAnalysisTabs extends StatefulWidget {
  final PyqAnalyticsModel analytics;

  const TrendAnalysisTabs({super.key, required this.analytics});

  @override
  State<TrendAnalysisTabs> createState() => _TrendAnalysisTabsState();
}

class _TrendAnalysisTabsState extends State<TrendAnalysisTabs> {
  int _selectedSegment = 0; // 0: Subject, 1: Topic, 2: Year, 3: Difficulty

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Detailed Trend Breakdown",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Segmented Control Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSegmentChip("Subjects", 0),
              const SizedBox(width: 8),
              _buildSegmentChip("Topics", 1),
              const SizedBox(width: 8),
              _buildSegmentChip("Years", 2),
              const SizedBox(width: 8),
              _buildSegmentChip("Difficulty", 3),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Selected Content List
        if (_selectedSegment == 0) _buildSubjectList(),
        if (_selectedSegment == 1) _buildTopicList(),
        if (_selectedSegment == 2) _buildYearList(),
        if (_selectedSegment == 3) _buildDifficultyList(),
      ],
    );
  }

  Widget _buildSegmentChip(String label, int index) {
    final isSelected = _selectedSegment == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedSegment = index),
    );
  }

  Widget _buildSubjectList() {
    final list = widget.analytics.subjectMetrics;
    if (list.isEmpty) return const Text("No subject data available.");
    return Column(
      children: list.map((sm) {
        return _buildProgressCard(
          title: sm.subject,
          accuracy: sm.accuracyPercent,
          attempted: sm.attemptedQuestions,
          total: sm.totalQuestions,
        );
      }).toList(),
    );
  }

  Widget _buildTopicList() {
    final list = widget.analytics.topicMetrics;
    if (list.isEmpty) return const Text("No topic data available.");
    return Column(
      children: list.map((tm) {
        return _buildProgressCard(
          title: tm.topic,
          subtitle: tm.subject,
          accuracy: tm.accuracyPercent,
          attempted: tm.attemptedQuestions,
          total: tm.totalQuestions,
        );
      }).toList(),
    );
  }

  Widget _buildYearList() {
    final list = widget.analytics.yearMetrics;
    if (list.isEmpty) return const Text("No year data available.");
    return Column(
      children: list.map((ym) {
        return _buildProgressCard(
          title: "Year ${ym.year}",
          accuracy: ym.accuracyPercent,
          attempted: ym.attemptedQuestions,
          total: ym.totalQuestions,
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyList() {
    final list = widget.analytics.difficultyMetrics;
    if (list.isEmpty) return const Text("No difficulty data available.");
    return Column(
      children: list.map((dm) {
        return _buildProgressCard(
          title: "${dm.difficulty} Level",
          accuracy: dm.accuracyPercent,
          attempted: dm.attemptedQuestions,
          total: dm.totalQuestions,
        );
      }).toList(),
    );
  }

  Widget _buildProgressCard({
    required String title,
    String? subtitle,
    required double accuracy,
    required int attempted,
    required int total,
  }) {
    final theme = Theme.of(context);
    final color = accuracy >= 70
        ? Colors.green
        : (accuracy < 50 && attempted > 0 ? Colors.red : Colors.blue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              Text(
                "${accuracy.toStringAsFixed(1)}%",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$attempted of $total Attempted",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: attempted == 0 ? 0.0 : accuracy / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Revision & Monthly Tracker Component
class RevisionMonthlyTracker extends StatelessWidget {
  final RevisionMetrics revisionMetrics;
  final MonthlyProgressMetrics monthlyMetrics;

  const RevisionMonthlyTracker({
    super.key,
    required this.revisionMetrics,
    required this.monthlyMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Revision & Active Progress",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Incorrect Bank Size",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${revisionMetrics.incorrectBankSize} Questions",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Weak Area Mastery",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${revisionMetrics.weakAreaMasteryPercent.toStringAsFixed(0)}%",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
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
