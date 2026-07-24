import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/daily_revision_queue.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/models/revision_schedule.dart';
import 'package:quizforge_upsc/services/revision_strategy.dart';
import 'package:quizforge_upsc/services/spaced_repetition_scheduler.dart';

class CustomTestRevisionStrategy implements RevisionStrategy {
  @override
  RevisionSchedule computeNextSchedule({
    required String questionId,
    required RevisionSchedule? existingSchedule,
    required bool isCorrect,
    required int confidenceRating,
    required String difficulty,
    required bool isBookmarked,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  }) {
    return RevisionSchedule(
      scheduleId: questionId,
      questionId: questionId,
      priorityScore: 99.0,
      priorityTier: 'Critical',
      aiRecommendationReason: 'Custom Test Strategy',
    );
  }

  @override
  double calculatePriorityScore({
    required DateTime nextReviewDue,
    required int mistakeCount,
    required bool isBookmarked,
    required String difficulty,
    required int confidenceRating,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  }) {
    return 99.0;
  }

  @override
  String getPriorityTier(double priorityScore) => 'Critical';

  @override
  DailyRevisionQueue buildDailyQueue({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  }) {
    return DailyRevisionQueue(
      date: DateTime.now(),
      totalDueCount: questions.length,
      criticalCount: questions.length,
      highCount: 0,
      mediumCount: 0,
      lowCount: 0,
      items: [],
      smartReminderMessage: 'Custom Test Queue',
      aiRecommendationSummary: 'Custom Test Summary',
    );
  }

  @override
  Map<String, List<RevisionQueueItem>> buildRevisionCalendar({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  }) =>
      {};

  @override
  List<String> buildSmartRecommendations({
    required List<RevisionQueueItem> items,
  }) =>
      ['Custom Recommendation'];
}

void main() {
  group('Intelligent Revision Strategy & Pluggable Engine Tests', () {
    late AdaptiveRevisionStrategy adaptiveStrategy;
    late PyqQuestionModel qHard;
    late PyqQuestionModel qEasy;
    late PyqQuestionModel qBookmarked;

    setUp(() {
      adaptiveStrategy = const AdaptiveRevisionStrategy();

      qHard = PyqQuestionModel(
        id: 'Q_HARD_01',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'Polity',
        topic: 'Executive',
        difficulty: 'Hard',
        question: 'Hard Polity question',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        userSelectedAnswer: 'B',
        timesAttempted: 3,
        timesCorrect: 1,
        isBookmarked: false,
        lastAttempted: DateTime.now().subtract(const Duration(days: 4)),
        explanation: PyqExplanation(official: 'Official Exp'),
        reference: 'Laxmikanth',
      );

      qEasy = PyqQuestionModel(
        id: 'Q_EASY_02',
        year: 2023,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'Geography',
        topic: 'Rivers',
        difficulty: 'Easy',
        question: 'Easy Geography question',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'C',
        officialAnswer: 'C',
        userSelectedAnswer: 'C',
        timesAttempted: 2,
        timesCorrect: 2,
        isBookmarked: false,
        lastAttempted: DateTime.now(),
        explanation: PyqExplanation(official: 'Official Exp 2'),
        reference: 'NCERT',
      );

      qBookmarked = PyqQuestionModel(
        id: 'Q_BM_03',
        year: 2022,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'Economy',
        topic: 'Banking',
        difficulty: 'Medium',
        question: 'Bookmarked Economy question',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'D',
        officialAnswer: 'D',
        userSelectedAnswer: 'D',
        timesAttempted: 1,
        timesCorrect: 1,
        isBookmarked: true,
        lastAttempted: DateTime.now().subtract(const Duration(days: 1)),
        explanation: PyqExplanation(official: 'Official Exp 3'),
        reference: 'Ramesh Singh',
      );
    });

    test('Schedules revision using all 6 inputs correctly', () {
      final schedule = adaptiveStrategy.computeNextSchedule(
        questionId: qHard.id,
        existingSchedule: null,
        isCorrect: false,
        confidenceRating: 1, // Again
        difficulty: qHard.difficulty,
        isBookmarked: qHard.isBookmarked,
        lastAttempt: qHard.lastAttempted,
        timeTakenSeconds: 130, // High time taken penalty
      );

      expect(schedule.questionId, equals(qHard.id));
      expect(schedule.mistakeCount, equals(1));
      expect(schedule.priorityTier, equals('Critical'));
      expect(schedule.priorityScore, greaterThanOrEqualTo(50.0));
      expect(schedule.aiRecommendationReason, contains('High response time'));
    });

    test(
        'Priority calculation increases score for time taken hesitancy & mistakes',
        () {
      final scoreWithHesitation = adaptiveStrategy.calculatePriorityScore(
        nextReviewDue: DateTime.now().subtract(const Duration(days: 2)),
        mistakeCount: 2,
        isBookmarked: true,
        difficulty: 'Hard',
        confidenceRating: 1,
        timeTakenSeconds: 130,
      );

      final scoreNormal = adaptiveStrategy.calculatePriorityScore(
        nextReviewDue: DateTime.now().add(const Duration(days: 10)),
        mistakeCount: 0,
        isBookmarked: false,
        difficulty: 'Easy',
        confidenceRating: 4,
        timeTakenSeconds: 30,
      );

      expect(scoreWithHesitation, greaterThan(scoreNormal));
      expect(adaptiveStrategy.getPriorityTier(scoreWithHesitation),
          equals('Critical'));
    });

    test('Edge Case: Null lastAttempt and 0 timeTaken handled gracefully', () {
      final score = adaptiveStrategy.calculatePriorityScore(
        nextReviewDue: DateTime.now(),
        mistakeCount: 0,
        isBookmarked: false,
        difficulty: 'Medium',
        confidenceRating: 3,
        lastAttempt: null,
        timeTakenSeconds: 0,
      );

      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(100.0));
    });

    test('Edge Case: Extreme confidence ratings (1 vs 4) scale priority', () {
      final scoreAgain = adaptiveStrategy.calculatePriorityScore(
        nextReviewDue: DateTime.now(),
        mistakeCount: 1,
        isBookmarked: false,
        difficulty: 'Medium',
        confidenceRating: 1, // Again (Low confidence)
      );

      final scoreEasy = adaptiveStrategy.calculatePriorityScore(
        nextReviewDue: DateTime.now(),
        mistakeCount: 1,
        isBookmarked: false,
        difficulty: 'Medium',
        confidenceRating: 4, // Easy (High confidence)
      );

      expect(scoreAgain, greaterThan(scoreEasy));
    });

    test('Builds Revision Calendar grouped by ISO Date string YYYY-MM-DD', () {
      final scheduleMap = <String, RevisionSchedule>{
        qHard.id: RevisionSchedule(
          scheduleId: qHard.id,
          questionId: qHard.id,
          nextReviewDue: DateTime(2026, 8, 1, 10, 0),
        ),
      };

      final calendar = adaptiveStrategy.buildRevisionCalendar(
        questions: [qHard],
        scheduleMap: scheduleMap,
      );

      expect(calendar.containsKey('2026-08-01'), isTrue);
      expect(calendar['2026-08-01']!.length, equals(1));
    });

    test('Generates Smart Recommendations for weak subjects & critical items',
        () {
      final queue = adaptiveStrategy.buildDailyQueue(
        questions: [qHard, qBookmarked, qEasy],
        scheduleMap: {},
      );

      final recs =
          adaptiveStrategy.buildSmartRecommendations(items: queue.items);
      expect(recs.isNotEmpty, isTrue);
    });

    test('SpacedRepetitionScheduler supports pluggable strategy replacement',
        () {
      // Set custom strategy
      SpacedRepetitionScheduler.setStrategy(CustomTestRevisionStrategy());
      expect(SpacedRepetitionScheduler.currentStrategy,
          isA<CustomTestRevisionStrategy>());

      final sched = SpacedRepetitionScheduler.computeNextSchedule(
        questionId: 'Q99',
        existingSchedule: null,
        isCorrect: true,
        confidenceRating: 3,
        difficulty: 'Medium',
        isBookmarked: false,
      );

      expect(sched.priorityScore, equals(99.0));
      expect(sched.aiRecommendationReason, equals('Custom Test Strategy'));

      // Restore default strategy
      SpacedRepetitionScheduler.setStrategy(const AdaptiveRevisionStrategy());
      expect(SpacedRepetitionScheduler.currentStrategy,
          isA<AdaptiveRevisionStrategy>());
    });
  });
}
