import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Material 3 Widget Tests', () {
    testWidgets('JourneyProgressCard renders correctly',
        (WidgetTester tester) async {
      final progress = JourneyProgress(
        journeyId: 'j_wt_1',
        overallProgress: 0.65,
        completedMilestonesCount: 3,
        totalMilestonesCount: 5,
        completedTasksCount: 8,
        totalTasksCount: 12,
        weeklyVelocityMinutes: 400,
        streakDays: 5,
        lastActiveAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyProgressCard(progress: progress),
          ),
        ),
      );

      expect(find.text('Journey Progress'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Milestones: 3/5'), findsOneWidget);
      expect(find.text('Streak: 5 days 🔥'), findsOneWidget);
    });

    testWidgets('MilestoneCard renders title and status',
        (WidgetTester tester) async {
      final milestone = JourneyMilestone(
        id: 'ms_w1',
        stageId: 'stg_1',
        title: 'Polity Basics',
        description: 'Read Preamble and Fundamental Rights',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        progress: 0.50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCard(milestone: milestone),
          ),
        ),
      );

      expect(find.text('Polity Basics'), findsOneWidget);
      expect(find.text('Read Preamble and Fundamental Rights'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });
}
