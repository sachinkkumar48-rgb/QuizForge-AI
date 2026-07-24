import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_recommendation/titan_recommendation.dart';

void main() {
  group('Recommendation Material 3 Widget Tests', () {
    const sampleReason = RecommendationReason(
      code: 'OVERDUE_RECALL',
      title: 'Active Recall Overdue',
      description: 'Concept is overdue for active recall based on SM-2.',
      weight: 0.95,
    );

    final sampleRecommendation = Recommendation(
      id: 'rec_test_1',
      title: 'Review Overdue: Indian Polity',
      topic: 'Indian Polity',
      actionType: 'Active Recall',
      priority: 'Urgent',
      confidence: 0.95,
      source: 'Revision Engine',
      reasons: const [sampleReason],
      estimatedStudyTimeMinutes: 15,
    );

    testWidgets('RecommendationPriorityBadge renders priority text and icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RecommendationPriorityBadge(priority: 'Urgent'),
          ),
        ),
      );

      expect(find.text('URGENT'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('RecommendationReasonChip renders title and percentage avatar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RecommendationReasonChip(reason: sampleReason),
          ),
        ),
      );

      expect(find.text('Active Recall Overdue'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets(
        'RecommendationCard renders title, priority, confidence, and action button',
        (WidgetTester tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationCard(
              recommendation: sampleRecommendation,
              onActionPressed: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Review Overdue: Indian Polity'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('95% match'), findsOneWidget);
      expect(find.text('Revision Engine'), findsOneWidget);
      expect(find.text('15 min study'), findsOneWidget);
      expect(find.text('Start Active Recall'), findsOneWidget);

      await tester.tap(find.text('Start Active Recall'));
      expect(actionTapped, isTrue);
    });

    testWidgets(
        'RecommendationSummaryCard renders active count and total study time',
        (WidgetTester tester) async {
      final recs = [
        sampleRecommendation,
        sampleRecommendation.copyWith(
          id: 'rec_test_2',
          priority: 'High',
          topic: 'Economy',
          estimatedStudyTimeMinutes: 25,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationSummaryCard(recommendations: recs),
          ),
        ),
      );

      expect(find.text('Personalized Study Plan'), findsOneWidget);
      expect(find.text('2 Active'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1 urgent action
      expect(find.text('40 min'), findsOneWidget); // 15 + 25 = 40 min
    });

    testWidgets(
        'RecommendationList renders list, priority filter chips, and responds to filter',
        (WidgetTester tester) async {
      final recs = [
        sampleRecommendation, // Urgent, topic: Indian Polity
        sampleRecommendation.copyWith(
          id: 'rec_high',
          priority: 'High',
          topic: 'Environment',
          title: 'Deep Dive: Environment',
          actionType: 'Concept Deep Dive',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationList(recommendations: recs),
          ),
        ),
      );

      expect(find.text('Review Overdue: Indian Polity'), findsOneWidget);
      expect(find.text('Deep Dive: Environment'), findsOneWidget);

      // Tap on 'Urgent' filter chip
      await tester.tap(find.text('Urgent'));
      await tester.pumpAndSettle();

      expect(find.text('Review Overdue: Indian Polity'), findsOneWidget);
      expect(find.text('Deep Dive: Environment'), findsNothing);
    });
  });
}
