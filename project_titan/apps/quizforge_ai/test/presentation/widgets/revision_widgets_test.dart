import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/widgets/revision/adaptive_schedule_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/revision/revision_filter_bar.dart';
import 'package:quizforge_ai/src/presentation/widgets/revision/revision_queue_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/revision/spaced_repetition_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/revision/topic_mastery_card.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('Adaptive Revision Engine M3 Widgets Tests', () {
    final now = DateTime(2026, 7, 24);

    final sampleItem = RevisionItem(
      id: 'rev_test_widget',
      topic: 'Indian Polity',
      subtopic: 'Writs & Fundamental Rights',
      questionId: 'q_polity_01',
      questionText: 'Which writ is issued for illegal detention?',
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      nextReviewDate: now.add(const Duration(days: 6)),
      lastReviewedAt: now,
      qualityRating: 4,
      masteryLevel: 'Learning',
      priority: 'Urgent',
      sourceTag: 'Quiz Mistake',
    );

    final sampleQueue = RevisionQueue(
      id: 'q_1',
      userId: 'user_titan',
      generatedAt: now,
      items: [sampleItem],
      dueTodayCount: 1,
      overdueCount: 0,
      masteredCount: 0,
      summary: 'Your active recall queue is up to date.',
    );

    testWidgets(
        'RevisionQueueCard renders item topic, subtopic, priority, and recall button',
        (WidgetTester tester) async {
      bool recallPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevisionQueueCard(
              item: sampleItem,
              onStartRecall: () => recallPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('Writs & Fundamental Rights'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Recall'), findsOneWidget);

      await tester.tap(find.text('Recall'));
      expect(recallPressed, isTrue);
    });

    testWidgets(
        'SpacedRepetitionCard renders SM-2 metrics and rating buttons 0-5',
        (WidgetTester tester) async {
      int? selectedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpacedRepetitionCard(
              item: sampleItem,
              onRateRecall: (rating) => selectedRating = rating,
            ),
          ),
        ),
      );

      expect(find.text('Spaced Repetition Metrics (SM-2)'), findsOneWidget);
      expect(find.text('Rate Your Recall Difficulty:'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Rating button 5

      await tester.tap(find.text('4'));
      expect(selectedRating, equals(4));
    });

    testWidgets('AdaptiveScheduleCard renders summary and counts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveScheduleCard(queue: sampleQueue),
          ),
        ),
      );

      expect(find.text('Adaptive Schedule'), findsOneWidget);
      expect(
          find.text('Your active recall queue is up to date.'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Due Today'), findsOneWidget);
    });

    testWidgets('TopicMasteryCard renders topic mastery overview bars',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TopicMasteryCard(
              topicMastery: {
                'Indian Polity': 85.0,
                'Indian Economy': 55.0,
              },
            ),
          ),
        ),
      );

      expect(find.text('Topic Mastery Overview'), findsOneWidget);
      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Indian Economy'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
    });

    testWidgets(
        'RevisionFilterBar renders category chips and filter urgency choices',
        (WidgetTester tester) async {
      String? selectedCat;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevisionFilterBar(
              selectedCategory: 'All',
              filterOption: 'All',
              onCategorySelected: (cat) => selectedCat = cat,
            ),
          ),
        ),
      );

      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);

      await tester.tap(find.text('Indian Polity'));
      expect(selectedCat, equals('Indian Polity'));
    });
  });
}
