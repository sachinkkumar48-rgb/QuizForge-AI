import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/mentor_result_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/mistake_analysis_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/pyq_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/revision_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/score_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/topic_analysis_card.dart';
import 'package:titan_analytics/titan_analytics.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Intelligent Results Dashboard M3 Cards Widget Tests', () {
    testWidgets('ScoreCard renders score metrics correctly', (tester) async {
      const metrics = ScoreMetrics(
        scoreObtained: 14.5,
        maxScore: 20.0,
        percentage: 72.5,
        totalQuestions: 10,
        correctCount: 7,
        wrongCount: 2,
        unansweredCount: 1,
        timeTaken: Duration(minutes: 10),
        accuracy: 77.8,
        percentileRank: 85.0,
        status: 'Good',
      );

      await tester
          .pumpWidget(buildTestableWidget(const ScoreCard(metrics: metrics)));

      expect(find.text('Score Summary'), findsOneWidget);
      expect(find.text('14.5'), findsOneWidget);
      expect(find.text('72.5%'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('85.0%'), findsOneWidget);
    });

    testWidgets('TopicAnalysisCard renders topics and mastery levels',
        (tester) async {
      const topics = [
        TopicPerformance(
          topic: 'Indian Polity',
          totalQuestions: 5,
          correctCount: 4,
          wrongCount: 1,
          accuracy: 80.0,
          masteryLevel: 'Master',
        ),
      ];

      await tester.pumpWidget(
          buildTestableWidget(const TopicAnalysisCard(topics: topics)));

      expect(find.text('Topic Breakdown'), findsOneWidget);
      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
    });

    testWidgets('MistakeAnalysisCard renders mistake taxonomy and insights',
        (tester) async {
      final mistakeAnalysis = MistakeAnalysis(
        conceptualErrors: 2,
        sillyErrors: 1,
        timePressureErrors: 0,
        skippedCount: 1,
        keyMistakeInsights: const ['Review Constitutional Amendments'],
      );

      await tester.pumpWidget(buildTestableWidget(
          MistakeAnalysisCard(mistakeAnalysis: mistakeAnalysis)));

      expect(find.text('Mistake Taxonomy'), findsOneWidget);
      expect(find.text('Conceptual: 2'), findsOneWidget);
      expect(find.text('Review Constitutional Amendments'), findsOneWidget);
    });

    testWidgets('MentorResultCard renders AI Mentor feedback', (tester) async {
      final feedback = MentorFeedback(
        summary: 'Great performance overall.',
        strengths: const ['Polity'],
        weakAreas: const ['Economy'],
        recommendation: 'Focus on Banking terms.',
        actionPlan: const ['Read Chapter 4'],
      );

      await tester.pumpWidget(
          buildTestableWidget(MentorResultCard(feedback: feedback)));

      expect(find.text('AI Mentor Insights'), findsOneWidget);
      expect(find.text('Great performance overall.'), findsOneWidget);
      expect(find.text('Focus on Banking terms.'), findsOneWidget);
      expect(find.text('Read Chapter 4'), findsOneWidget);
    });

    testWidgets('RevisionCard renders revision schedule', (tester) async {
      final revision = RevisionRecommendation(
        recommendedTopics: const ['Economy'],
        priorityLevel: 'High',
        scheduledDate: DateTime(2026, 7, 26),
        suggestedResources: const ['NCERT Economics'],
      );

      await tester
          .pumpWidget(buildTestableWidget(RevisionCard(revision: revision)));

      expect(find.text('Revision Schedule'), findsOneWidget);
      expect(find.text('Priority: High'), findsOneWidget);
      expect(find.text('Economy'), findsOneWidget);
      expect(find.text('NCERT Economics'), findsOneWidget);
    });

    testWidgets('PYQCard renders PYQ correlation metrics', (tester) async {
      final pyq = PyqCorrelation(
        matchedPyqCount: 8,
        relevanceScore: 88.0,
        trendAnalysis: 'Strong alignment with past 5 years papers.',
        keyPyqTopics: const ['Preamble & Fundamental Rights'],
      );

      await tester.pumpWidget(buildTestableWidget(PYQCard(pyq: pyq)));

      expect(find.text('UPSC PYQ Correlation'), findsOneWidget);
      expect(find.text('88% Match'), findsOneWidget);
      expect(find.text('Strong alignment with past 5 years papers.'),
          findsOneWidget);
      expect(find.text('Preamble & Fundamental Rights'), findsOneWidget);
    });
  });
}
