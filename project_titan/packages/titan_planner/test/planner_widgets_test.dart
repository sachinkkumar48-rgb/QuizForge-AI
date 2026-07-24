import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_planner/titan_planner.dart';

void main() {
  group('Daily Study Planner Material 3 Widget Tests', () {
    final now = DateTime(2026, 7, 24, 9, 0);

    const sampleTask = StudyTask(
      id: 'task_widget_1',
      title: 'Active Recall: Indian Polity',
      topic: 'Indian Polity',
      category: 'Revision',
      priority: 'Urgent',
      estimatedDurationMinutes: 20,
      scheduledStartTime: null,
      isCompleted: false,
      isRollover: true,
    );

    const sampleSummary = StudySummary(
      totalTasksCount: 3,
      completedTasksCount: 1,
      totalAllocatedMinutes: 90,
      completedMinutes: 30,
      revisionMinutes: 30,
      learningMinutes: 30,
      practiceMinutes: 30,
      currentAffairsMinutes: 0,
      completionPercentage: 33.3,
      topFocusTopic: 'Indian Polity',
    );

    final samplePlan = StudyPlan(
      id: 'plan_test_01',
      userId: 'user_widget_test',
      planDate: now,
      targetStudyTimeMinutes: 180,
      tasks: const [sampleTask],
      summary: sampleSummary,
      generatedAt: now,
    );

    testWidgets(
        'StudyTaskCard renders task info, priority badge, and rollover tag',
        (WidgetTester tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyTaskCard(
              task: sampleTask,
              onToggleCompletion: (val) => toggleCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Active Recall: Indian Polity'), findsOneWidget);
      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('Carried Forward'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      expect(toggleCalled, isTrue);
    });

    testWidgets('DailySummaryCard renders budget time and top focus topic',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailySummaryCard(
              summary: sampleSummary,
              targetStudyTimeMinutes: 180,
            ),
          ),
        ),
      );

      expect(find.text('Daily Study Plan'), findsOneWidget);
      expect(find.text('Budget: 3h'), findsOneWidget);
      expect(find.text('Top Focus: Indian Polity'), findsOneWidget);
      expect(find.text('Revision: 30m'), findsOneWidget);
    });

    testWidgets(
        'ProgressIndicatorCard renders percentage and completed tasks count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorCard(summary: sampleSummary),
          ),
        ),
      );

      expect(find.text('Daily Progress'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('1 / 3 tasks'), findsOneWidget);
      expect(find.text('30 / 90 mins'), findsOneWidget);
    });

    testWidgets('StudyTimeline renders task with time slot',
        (WidgetTester tester) async {
      final taskWithTime = sampleTask.copyWith(scheduledStartTime: now);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyTimeline(tasks: [taskWithTime]),
          ),
        ),
      );

      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('Active Recall: Indian Polity'), findsOneWidget);
    });

    testWidgets(
        'StudyPlanCard renders daily summary, progress card, and timeline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudyPlanCard(plan: samplePlan),
            ),
          ),
        ),
      );

      expect(find.text('Daily Study Plan'), findsOneWidget);
      expect(find.text('Daily Progress'), findsOneWidget);
      expect(find.text('Chronological Timeline'), findsOneWidget);
      expect(find.text('Active Recall: Indian Polity'), findsOneWidget);
    });
  });
}
