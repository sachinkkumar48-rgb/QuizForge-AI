import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('Learning Flow Widget Tests', () {
    testWidgets(
        'LearningFlowScreen renders StudySessionBar and CheckpointTimeline',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LearningFlowScreen(
              userId: 'u_w1',
              courseId: 'c1',
              courseTitle: 'Polity & Governance',
              lessonId: 'l1',
              lessonTitle: 'Preamble',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StudySessionBar), findsOneWidget);
      expect(find.byType(CheckpointTimeline), findsOneWidget);
      expect(find.text('Preamble'), findsAtLeastNWidgets(1));
    });

    testWidgets('StudySessionSummary renders metrics and achievements',
        (tester) async {
      final summary = LearningFlowSummary(
        sessionId: 's_w',
        totalDurationMinutes: 25,
        videoWatchTimeMinutes: 15,
        notesCreatedCount: 3,
        aiQuestionsAskedCount: 2,
        quizAccuracy: 0.9,
        revisionScheduledCount: 2,
        achievementsEarned: const ['🔥 7-Day Streak'],
        completedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudySessionSummary(summary: summary),
          ),
        ),
      );

      expect(find.text('SESSION SUMMARY'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
    });
  });
}
