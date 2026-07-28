import 'package:flutter/material.dart';

import '../models/dashboard_snapshot.dart';
import 'executive_summary_card.dart';
import 'goal_progress_card.dart';
import 'knowledge_insight_card.dart';
import 'learning_score_gauge.dart';
import 'mentor_insight_card.dart';
import 'performance_trend_chart.dart';
import 'planner_overview_card.dart';
import 'productivity_card.dart';
import 'revision_overview_card.dart';
import 'search_insight_card.dart';

/// Material 3 executive grid layout combining all executive dashboard cards and gauges.
class DashboardGrid extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final VoidCallback? onRevisionTap;
  final VoidCallback? onConsultMentorTap;
  final ValueChanged<String>? onSearchQueryTap;

  const DashboardGrid({
    super.key,
    required this.snapshot,
    this.onRevisionTap,
    this.onConsultMentorTap,
    this.onSearchQueryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        ExecutiveSummaryCard(snapshot: snapshot),
        const SizedBox(height: 12.0),
        ProductivityCard(statistics: snapshot.statistics),
        const SizedBox(height: 12.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: LearningScoreGauge(
                readinessScore: snapshot.readinessScore,
                label: 'UPSC Readiness',
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              flex: 6,
              child: PerformanceTrendChart(trend: snapshot.trend),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        PlannerOverviewCard(
          completedHours: snapshot.statistics.totalStudyHours,
          targetHours: 6.0,
          completedTasksCount: snapshot.statistics.completedTasksCount,
        ),
        const SizedBox(height: 12.0),
        RevisionOverviewCard(
          pendingRevisionsCount: snapshot.statistics.pendingRevisionsCount,
          onTap: onRevisionTap,
        ),
        const SizedBox(height: 12.0),
        MentorInsightCard(
          mentorTip: snapshot.insights.mentorTip,
          onAskMentor: onConsultMentorTap,
        ),
        const SizedBox(height: 12.0),
        KnowledgeInsightCard(
          weakSubjects: snapshot.insights.weakAreasToAddress,
          strongSubjects: snapshot.insights.strongAreasToMaintain,
        ),
        const SizedBox(height: 12.0),
        SearchInsightCard(
          recentQueries: const ['Fundamental Rights', 'Monsoon winds'],
          onQueryTap: onSearchQueryTap,
        ),
        if (snapshot.goals.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          ...snapshot.goals.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GoalProgressCard(goal: g),
              )),
        ],
      ],
    );
  }
}
