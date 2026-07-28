import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('Smart Assessment M3 Responsive Widgets Tests', () {
    testWidgets('AssessmentCard renders title and duration', (tester) async {
      const blueprint = AssessmentBlueprint(
        id: 'bp1',
        title: 'Polity Blueprint',
        subjectCategory: 'Polity',
      );

      final assessment = Assessment(
        id: 'a1',
        title: 'Polity Prelims Speed Test',
        description: 'Test your speed on Polity questions',
        type: AssessmentType.practiceTest,
        blueprint: blueprint,
        totalDurationMinutes: 30,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssessmentCard(assessment: assessment),
          ),
        ),
      );

      expect(find.text('Polity Prelims Speed Test'), findsOneWidget);
      expect(find.textContaining('30 mins'), findsOneWidget);
    });

    testWidgets('ReadinessScoreCard renders percentage and prediction',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadinessScoreCard(
              readinessScore: 82.0,
              examPrediction: 'High Probability of Clearing Prelims Baseline',
            ),
          ),
        ),
      );

      expect(find.text('82%'), findsOneWidget);
      expect(find.text('High Probability of Clearing Prelims Baseline'),
          findsOneWidget);
    });
  });
}
