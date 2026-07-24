import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/models/revision_schedule.dart';
import 'package:quizforge_upsc/services/spaced_repetition_scheduler.dart';

void main() {
  group('Intelligent Spaced Repetition Scheduler Tests', () {
    late PyqQuestionModel qHardMistake;
    late PyqQuestionModel qBookmarkedEasy;
    late PyqQuestionModel qNormal;

    setUp(() {
      qHardMistake = PyqQuestionModel(
        id: 'Q_HARD_01',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'Polity',
        topic: 'Constitutional Bodies',
        difficulty: 'Hard',
        question: 'Hard question text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        userSelectedAnswer: 'B',
        timesAttempted: 3,
        timesCorrect: 1,
        isBookmarked: true,
        lastAttempted: DateTime.now().subtract(const Duration(days: 5)),
        explanation: PyqExplanation(official: 'Exp'),
        reference: 'Ref',
      );

      qBookmarkedEasy = PyqQuestionModel(
        id: 'Q_BOOKMARK_02',
        year: 2023,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'Economy',
        topic: 'Monetary Policy',
        difficulty: 'Easy',
        question: 'Easy bookmarked question text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'C',
        officialAnswer: 'C',
        userSelectedAnswer: 'C',
        timesAttempted: 1,
        timesCorrect: 1,
        isBookmarked: true,
        lastAttempted: DateTime.now().subtract(const Duration(days: 1)),
        explanation: PyqExplanation(official: 'Exp 2'),
        reference: 'Ref 2',
      );

      qNormal = PyqQuestionModel(
        id: 'Q_NORMAL_03',
        year: 2022,
        exam: 'UPSC CSE',
        paper: 'GS Paper I',
        subject: 'History',
        topic: 'Modern History',
        difficulty: 'Medium',
        question: 'Normal question text',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'D',
        officialAnswer: 'D',
        userSelectedAnswer: 'D',
        timesAttempted: 2,
        timesCorrect: 2,
        isBookmarked: false,
        lastAttempted: DateTime.now().subtract(const Duration(days: 14)),
        explanation: PyqExplanation(official: 'Exp 3'),
        reference: 'Ref 3',
      );
    });

    test(
        'Computes next schedule with 5 inputs (Incorrect, Bookmarked, Difficulty, Time, Confidence)',
        () {
      final schedule = SpacedRepetitionScheduler.computeNextSchedule(
        questionId: qHardMistake.id,
        existingSchedule: null,
        isCorrect: false,
        confidenceRating: 1, // Again
        difficulty: qHardMistake.difficulty,
        isBookmarked: qHardMistake.isBookmarked,
      );

      expect(schedule.questionId, equals(qHardMistake.id));
      expect(schedule.mistakeCount, equals(1));
      expect(schedule.confidenceRating, equals(1));
      expect(schedule.priorityTier, equals('Critical'));
      expect(schedule.priorityScore, greaterThanOrEqualTo(50.0));
      expect(schedule.aiRecommendationReason, contains('1 past mistake(s)'));
    });

    test(
        'Priority Score calculation factors difficulty, bookmarks, and confidence correctly',
        () {
      final hardScore = SpacedRepetitionScheduler.calculatePriorityScore(
        nextReviewDue: DateTime.now().subtract(const Duration(days: 2)),
        mistakeCount: 2,
        isBookmarked: true,
        difficulty: 'Hard',
        confidenceRating: 1,
      );

      final easyScore = SpacedRepetitionScheduler.calculatePriorityScore(
        nextReviewDue: DateTime.now().add(const Duration(days: 10)),
        mistakeCount: 0,
        isBookmarked: false,
        difficulty: 'Easy',
        confidenceRating: 4,
      );

      expect(hardScore, greaterThan(easyScore));
      expect(SpacedRepetitionScheduler.getPriorityTier(hardScore),
          equals('Critical'));
      expect(
          SpacedRepetitionScheduler.getPriorityTier(easyScore), equals('Low'));
    });

    test('Builds Daily Revision Queue ranked by Priority Score descending', () {
      final scheduleMap = <String, RevisionSchedule>{
        qHardMistake.id: RevisionSchedule(
          scheduleId: qHardMistake.id,
          questionId: qHardMistake.id,
          lastReviewed: DateTime.now().subtract(const Duration(days: 5)),
          nextReviewDue: DateTime.now().subtract(const Duration(days: 2)),
          mistakeCount: 2,
          confidenceRating: 1,
          priorityScore: 90.0,
          priorityTier: 'Critical',
        ),
        qBookmarkedEasy.id: RevisionSchedule(
          scheduleId: qBookmarkedEasy.id,
          questionId: qBookmarkedEasy.id,
          lastReviewed: DateTime.now(),
          nextReviewDue: DateTime.now().add(const Duration(days: 5)),
          mistakeCount: 0,
          confidenceRating: 4,
          priorityScore: 30.0,
          priorityTier: 'Medium',
        ),
      };

      final queue = SpacedRepetitionScheduler.buildDailyQueue(
        questions: [qHardMistake, qBookmarkedEasy, qNormal],
        scheduleMap: scheduleMap,
      );

      expect(queue.totalDueCount, greaterThanOrEqualTo(2));
      expect(queue.items.first.question.id, equals(qHardMistake.id));
      expect(queue.smartReminderMessage, contains('Critical'));
    });

    test('Generates Smart Reminders and AI Recommendation Hook outputs', () {
      final reminder = SpacedRepetitionScheduler.generateSmartReminder(
        totalDue: 5,
        criticalCount: 2,
        highCount: 3,
      );
      expect(reminder, contains('Critical'));

      final aiSummary = SpacedRepetitionScheduler.generateAiRecommendation([]);
      expect(aiSummary, contains('AI Recommendation'));
    });
  });
}
