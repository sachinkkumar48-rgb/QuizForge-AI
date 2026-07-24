import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/services/analytics_engine.dart';

void main() {
  group('Professional Analytics Engine Unit Tests', () {
    late PyqQuestionModel q1;
    late PyqQuestionModel q2;
    late PyqQuestionModel q3;
    late PyqQuestionModel q4;

    setUp(() {
      q1 = PyqQuestionModel(
        id: 'Q001',
        year: 2025,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'Polity',
        topic: 'Preamble',
        difficulty: 'Easy',
        question: 'Question 1 text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        userSelectedAnswer: 'A',
        explanation: PyqExplanation(official: 'Official Exp'),
        reference: 'Ref 1',
        isBookmarked: true,
        timesAttempted: 2,
        timesCorrect: 2,
        lastAttempted: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['Constitution'],
      );

      q2 = PyqQuestionModel(
        id: 'Q002',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'Economy',
        topic: 'Inflation',
        difficulty: 'Hard',
        question: 'Question 2 text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'B',
        officialAnswer: 'B',
        userSelectedAnswer: 'A',
        explanation: PyqExplanation(official: 'Official Exp 2'),
        reference: 'Ref 2',
        isBookmarked: false,
        timesAttempted: 1,
        timesCorrect: 0,
        lastAttempted: DateTime.now(),
        tags: ['Banking'],
      );

      q3 = PyqQuestionModel(
        id: 'Q003',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'History',
        topic: 'Ancient India',
        difficulty: 'Medium',
        question: 'Question 3 text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'C',
        officialAnswer: 'C',
        explanation: PyqExplanation(official: 'Official Exp 3'),
        reference: 'Ref 3',
        isBookmarked: true,
        timesAttempted: 0,
        timesCorrect: 0,
        tags: ['Art'],
      );

      q4 = PyqQuestionModel(
        id: 'Q004',
        year: 2023,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'Polity',
        topic: 'Parliament',
        difficulty: 'Medium',
        question: 'Question 4 text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'D',
        officialAnswer: 'D',
        userSelectedAnswer: 'D',
        explanation: PyqExplanation(official: 'Official Exp 4'),
        reference: 'Ref 4',
        isBookmarked: false,
        timesAttempted: 3,
        timesCorrect: 3,
        lastAttempted: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['Legislature'],
      );
    });

    test('Computes Accuracy, Speed, Consistency, and Retention metrics', () {
      final analytics = AnalyticsEngine.computeFullAnalytics([q1, q2, q3, q4]);

      // Total counts
      expect(analytics.totalQuestions, equals(4));
      expect(analytics.totalAttempted, equals(3));
      expect(analytics.totalBookmarked, equals(2));

      // Accuracy
      expect(analytics.accuracyMetrics.totalAttempted, equals(3));
      expect(analytics.accuracyMetrics.overallAccuracyPercent, greaterThan(0));

      // Speed
      expect(analytics.speedMetrics.avgSecondsPerQuestion, greaterThan(0));
      expect(analytics.speedMetrics.speedStatus, isNotEmpty);

      // Consistency
      expect(analytics.consistencyMetrics.totalActiveDays, greaterThan(0));

      // Retention
      expect(analytics.retentionMetrics.repeatAttemptCount, greaterThan(0));
    });

    test('Classifies Weak Areas and Strong Areas', () {
      final analytics = AnalyticsEngine.computeFullAnalytics([q1, q2, q3, q4]);

      expect(analytics.strongSubjects, contains('Polity'));
      expect(analytics.weakSubjects, contains('Economy'));
    });

    test('Computes Subject, Topic, Year, and Difficulty trends', () {
      final analytics = AnalyticsEngine.computeFullAnalytics([q1, q2, q3, q4]);

      expect(analytics.subjectMetrics.length, equals(3));
      expect(analytics.yearMetrics.length, equals(3));
      expect(analytics.topicMetrics.length, equals(4));
      expect(analytics.difficultyMetrics.length, greaterThanOrEqualTo(2));
    });

    test('Computes Streaks, Revision, and Monthly progress metrics', () {
      final analytics = AnalyticsEngine.computeFullAnalytics([q1, q2, q3, q4]);

      expect(
          analytics.streakMetrics.currentDailyStreak, greaterThanOrEqualTo(0));
      expect(analytics.streakMetrics.maxDailyStreak, greaterThanOrEqualTo(0));

      expect(analytics.revisionMetrics.incorrectBankSize, equals(1));
      expect(analytics.revisionMetrics.bookmarkedCount, equals(2));

      expect(analytics.monthlyMetrics.monthlyAttemptsMap.isNotEmpty, isTrue);
    });
  });
}
