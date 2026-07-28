import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  final testSnapshot = DashboardSnapshot.empty(userId: 'u_1');

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Material 3 Dashboard Widgets Tests', () {
    testWidgets('DashboardHeader renders learner name and exam',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        DashboardHeader(snapshot: testSnapshot),
      ));

      expect(find.textContaining('Welcome, Learner'), findsOneWidget);
      expect(find.textContaining('Target: UPSC CSE'), findsOneWidget);
    });

    testWidgets('ExecutiveSummaryCard renders top recommendation',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        ExecutiveSummaryCard(snapshot: testSnapshot),
      ));

      expect(find.text('Executive Summary'), findsOneWidget);
      expect(
          find.text(testSnapshot.insights.topRecommendation), findsOneWidget);
    });

    testWidgets('LearningScoreGauge renders readiness score', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const LearningScoreGauge(readinessScore: 78.5),
      ));

      expect(find.text('78.5%'), findsOneWidget);
    });

    testWidgets('PerformanceTrendChart renders trend indicator',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        PerformanceTrendChart(
            trend: testSnapshot.trend.copyWith(trendDirection: 'improving')),
      ));

      expect(find.text('Performance Trend'), findsOneWidget);
      expect(find.text('IMPROVING'), findsOneWidget);
    });

    testWidgets('RevisionOverviewCard responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestableWidget(
        RevisionOverviewCard(
          pendingRevisionsCount: 15,
          onTap: () => tapped = true,
        ),
      ));

      expect(find.text('Spaced Repetition Queue'), findsOneWidget);
      await tester.tap(find.text('Revise'));
      expect(tapped, isTrue);
    });

    testWidgets('PlannerOverviewCard renders hours completed', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const PlannerOverviewCard(
          completedHours: 4.5,
          targetHours: 6.0,
          completedTasksCount: 5,
        ),
      ));

      expect(find.text('Daily Study Plan'), findsOneWidget);
      expect(find.text('4.5 / 6.0 hrs'), findsOneWidget);
    });

    testWidgets('MentorInsightCard renders tip and consult button',
        (tester) async {
      bool consulted = false;
      await tester.pumpWidget(buildTestableWidget(
        MentorInsightCard(
          mentorTip: 'Study hard!',
          onAskMentor: () => consulted = true,
        ),
      ));

      expect(find.text('AI Mentor Insight'), findsOneWidget);
      expect(find.text('Study hard!'), findsOneWidget);
      await tester.tap(find.text('Consult Mentor'));
      expect(consulted, isTrue);
    });

    testWidgets('KnowledgeInsightCard renders weak and strong areas',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const KnowledgeInsightCard(
          weakSubjects: ['Polity'],
          strongSubjects: ['Geography'],
        ),
      ));

      expect(find.text('Knowledge Graph Insights'), findsOneWidget);
      expect(find.text('Polity'), findsOneWidget);
      expect(find.text('Geography'), findsOneWidget);
    });

    testWidgets('SearchInsightCard renders recent queries', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const SearchInsightCard(recentQueries: ['Fundamental Rights']),
      ));

      expect(find.text('Recent Search Trends'), findsOneWidget);
      expect(find.text('Fundamental Rights'), findsOneWidget);
    });

    testWidgets('GoalProgressCard renders goal title and progress',
        (tester) async {
      final goal = GoalProgress(
        title: 'Complete 10 PYQs',
        category: 'Practice',
        targetValue: 10.0,
        currentValue: 5.0,
        deadline: DateTime.now(),
      );

      await tester.pumpWidget(buildTestableWidget(
        GoalProgressCard(goal: goal),
      ));

      expect(find.text('Complete 10 PYQs'), findsOneWidget);
      expect(find.text('5.0 / 10.0 hrs'), findsOneWidget);
    });

    testWidgets('ProductivityCard renders streak and stats', (tester) async {
      const stats =
          StudyStatistics(currentStreakDays: 10, totalQuestionsAttempted: 200);

      await tester.pumpWidget(buildTestableWidget(
        const ProductivityCard(statistics: stats),
      ));

      expect(find.text('10 Days'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('DashboardGrid renders full dashboard view', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DashboardGrid(snapshot: testSnapshot),
        ),
      ));

      expect(find.byType(DashboardGrid), findsOneWidget);
      expect(find.byType(ExecutiveSummaryCard), findsOneWidget);
    });
  });
}
