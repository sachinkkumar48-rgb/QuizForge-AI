import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('Phase 8D: TopicMastery & LearnerProfile Domain Tests', () {
    test('TopicMastery calculates Bayesian-smoothed score and confidence', () {
      final initial = TopicMastery.initial('Polity', documentId: 'doc_1');
      expect(initial.topic, equals('Polity'));
      expect(initial.attempts, equals(0));
      expect(initial.masteryScore, equals(0.0));
      expect(initial.confidence, equals(0.0));
      expect(initial.hasAttempted, isFalse);

      // Single attempt with 1 correct -> smoothed to (1+1)/(1+2) = 2/3 = 0.666
      final afterOne =
          TopicMastery(topic: 'Polity', attempts: 1, correct: 1, incorrect: 0);
      expect(afterOne.accuracy, equals(1.0));
      expect(afterOne.masteryScore, closeTo(0.667, 0.01));
      expect(afterOne.confidence, closeTo(1.0 / 6.0, 0.01));
      expect(afterOne.hasAttempted, isTrue);

      // 10 attempts with 9 correct -> smoothed to (9+1)/(10+2) = 10/12 = 0.833, confidence = 10/15 = 0.667
      final solid =
          TopicMastery(topic: 'Polity', attempts: 10, correct: 9, incorrect: 1);
      expect(solid.accuracy, equals(0.90));
      expect(solid.masteryScore, closeTo(0.833, 0.01));
      expect(solid.isStrong, isTrue);
      expect(solid.isWeak, isFalse);
    });

    test('LearnerProfile maintains immutability and extracts weak/strong areas',
        () {
      final empty = LearnerProfile.empty(learnerId: 'user_123');
      expect(empty.learnerId, equals('user_123'));
      expect(empty.isEmpty, isTrue);
      expect(empty.totalAssessments, equals(0));
      expect(empty.overallAccuracy, equals(0.0));
      expect(empty.hasWeakTopics, isFalse);

      final weakTopic = TopicMastery(
        topic: 'Economics',
        attempts: 5,
        correct: 1,
        incorrect: 4,
        masteryScore: 0.35,
      );
      final strongTopic = TopicMastery(
        topic: 'Polity',
        attempts: 10,
        correct: 9,
        incorrect: 1,
        masteryScore: 0.85,
        confidence: 0.70,
      );

      final profile = LearnerProfile(
        learnerId: 'user_123',
        totalAssessments: 2,
        totalQuestionsAttempted: 15,
        totalCorrect: 10,
        totalIncorrect: 5,
        topicPerformance: {
          'Economics': weakTopic,
          'Polity': strongTopic,
        },
      );

      expect(profile.isEmpty, isFalse);
      expect(profile.weakTopics, contains('Economics'));
      expect(profile.strongTopics, contains('Polity'));
      expect(profile.hasWeakTopics, isTrue);
      expect(profile.hasStrongTopics, isTrue);
      expect(profile.masteryLevels['Economics'], equals(0.35));
      expect(profile.masteryLevels['Polity'], equals(0.85));
    });
  });

  group('Phase 8D: DifficultyAdapter Service Tests', () {
    const adapter = DifficultyAdapter();

    test('recommends step-down difficulty for weak or declining topics', () {
      final weakTopic = TopicMastery(
        topic: 'History',
        attempts: 4,
        correct: 1,
        incorrect: 3,
        accuracy: 0.25,
        masteryScore: 0.30,
      );

      expect(
        adapter.recommendDifficultyForTopic(weakTopic,
            currentDifficulty: QuizDifficulty.hard),
        equals(QuizDifficulty.medium),
      );
      expect(
        adapter.recommendDifficultyForTopic(weakTopic,
            currentDifficulty: QuizDifficulty.medium),
        equals(QuizDifficulty.easy),
      );
      expect(
        adapter.recommendDifficultyForTopic(weakTopic,
            currentDifficulty: QuizDifficulty.easy),
        equals(QuizDifficulty.easy),
      );
    });

    test(
        'recommends step-up difficulty for mastered topics with solid confidence',
        () {
      final masteredTopic = TopicMastery(
        topic: 'Geography',
        attempts: 10,
        correct: 9,
        incorrect: 1,
        accuracy: 0.90,
        confidence: 0.60,
        masteryScore: 0.85,
      );

      expect(
        adapter.recommendDifficultyForTopic(masteredTopic,
            currentDifficulty: QuizDifficulty.easy),
        equals(QuizDifficulty.medium),
      );
      expect(
        adapter.recommendDifficultyForTopic(masteredTopic,
            currentDifficulty: QuizDifficulty.medium),
        equals(QuizDifficulty.hard),
      );
      expect(
        adapter.recommendDifficultyForTopic(masteredTopic,
            currentDifficulty: QuizDifficulty.hard),
        equals(QuizDifficulty.hard),
      );
    });

    test(
        'recommends overall difficulty based on learner profile aggregate metrics',
        () {
      final emptyProfile = LearnerProfile.empty();
      expect(adapter.recommendOverallDifficulty(emptyProfile),
          equals(QuizDifficulty.medium));

      final weakProfile = LearnerProfile(
        learnerId: 'learner_1',
        totalAssessments: 1,
        totalQuestionsAttempted: 10,
        totalCorrect: 3,
        totalIncorrect: 7,
        overallAccuracy: 0.30,
        overallMastery: 0.35,
      );
      expect(adapter.recommendOverallDifficulty(weakProfile),
          equals(QuizDifficulty.easy));

      final strongProfile = LearnerProfile(
        learnerId: 'learner_2',
        totalAssessments: 5,
        totalQuestionsAttempted: 50,
        totalCorrect: 45,
        totalIncorrect: 5,
        overallAccuracy: 0.90,
        overallMastery: 0.82,
      );
      expect(adapter.recommendOverallDifficulty(strongProfile),
          equals(QuizDifficulty.hard));
    });
  });

  group('Phase 8D: ReviewScheduler Spaced Repetition Tests', () {
    const scheduler = ReviewScheduler();
    final now = DateTime(2026, 8, 23, 10, 0);

    test('schedules initial review item with default interval', () {
      final item = scheduler.scheduleItem(
        id: 'rev_1',
        topic: 'Constitutional Law',
        scheduledAt: now,
        sourceChunkId: 'chunk_42',
        pageNumber: 5,
        documentId: 'doc_polity',
      );

      expect(item.id, equals('rev_1'));
      expect(item.topic, equals('Constitutional Law'));
      expect(item.status, equals(ReviewStatus.learning));
      expect(item.nextReviewAt, equals(now.add(const Duration(days: 1))));
      expect(item.consecutiveCorrect, equals(0));
      expect(item.pageNumber, equals(5));
      expect(item.sourceChunkId, equals('chunk_42'));
    });

    test('progresses along interval ladder upon consecutive correct answers',
        () {
      var item = scheduler.scheduleItem(
          id: 'rev_2', topic: 'Preamble', scheduledAt: now);

      // Attempt 1: Correct -> Interval = 3 days
      item =
          scheduler.markAttempt(item: item, isCorrect: true, attemptTime: now);
      expect(item.consecutiveCorrect, equals(1));
      expect(item.status, equals(ReviewStatus.learning));
      expect(item.reviewInterval, equals(const Duration(days: 3)));
      expect(item.nextReviewAt, equals(now.add(const Duration(days: 3))));

      // Attempt 2: Correct -> Interval = 7 days
      item = scheduler.markAttempt(
          item: item,
          isCorrect: true,
          attemptTime: now.add(const Duration(days: 3)));
      expect(item.consecutiveCorrect, equals(2));
      expect(item.status, equals(ReviewStatus.learning));
      expect(item.reviewInterval, equals(const Duration(days: 7)));

      // Attempt 3: Correct -> Mastered, Interval = 14 days
      item = scheduler.markAttempt(
          item: item,
          isCorrect: true,
          attemptTime: now.add(const Duration(days: 10)));
      expect(item.consecutiveCorrect, equals(3));
      expect(item.status, equals(ReviewStatus.mastered));
      expect(item.reviewInterval, equals(const Duration(days: 14)));

      // Attempt 4: Incorrect -> Reset to learning & 1 day interval
      item = scheduler.markAttempt(
          item: item,
          isCorrect: false,
          attemptTime: now.add(const Duration(days: 24)));
      expect(item.consecutiveCorrect, equals(0));
      expect(item.status, equals(ReviewStatus.learning));
      expect(item.reviewInterval, equals(const Duration(days: 1)));
      expect(item.nextReviewAt, equals(now.add(const Duration(days: 25))));
    });

    test('getDueItems filters and sorts overdue items accurately', () {
      final pastItem = ReviewScheduleItem(
        id: 'rev_past',
        topic: 'Taxation',
        nextReviewAt: now.subtract(const Duration(hours: 2)),
        lastAttemptAt: now.subtract(const Duration(days: 2)),
      );
      final futureItem = ReviewScheduleItem(
        id: 'rev_future',
        topic: 'Environment',
        nextReviewAt: now.add(const Duration(days: 3)),
        lastAttemptAt: now,
      );

      final due =
          scheduler.getDueItems(items: [futureItem, pastItem], asOf: now);
      expect(due.length, equals(1));
      expect(due.first.id, equals('rev_past'));
    });
  });

  group('Phase 8D: AdaptiveAssessmentStrategy & Question Ranking Tests', () {
    const strategy = AdaptiveAssessmentStrategy();

    test(
        'generates adaptive plan targeting weak topics and appropriate difficulty',
        () {
      final profile = LearnerProfile(
        learnerId: 'user_1',
        totalAssessments: 2,
        totalQuestionsAttempted: 10,
        totalCorrect: 4,
        totalIncorrect: 6,
        overallAccuracy: 0.40,
        overallMastery: 0.38,
        topicPerformance: {
          'Modern History': TopicMastery(
            topic: 'Modern History',
            attempts: 5,
            correct: 1,
            incorrect: 4,
            accuracy: 0.20,
            masteryScore: 0.28,
            sourceChunkIds: const ['chunk_h1', 'chunk_h2'],
          ),
        },
      );

      final baseBlueprint = AssessmentBlueprint(
        documentId: 'doc_history',
        targetQuestions: 5,
        difficulty: QuizDifficulty.medium,
      );

      final plan = strategy.createPlan(
        profile: profile,
        baseBlueprint: baseBlueprint,
      );

      expect(plan.recommendedDifficulty, equals(QuizDifficulty.easy));
      expect(plan.targetTopics, contains('Modern History'));
      expect(plan.remedialTopics, contains('Modern History'));
      expect(plan.sourceChunks, contains('chunk_h1'));
      expect(plan.blueprint.difficulty, equals(QuizDifficulty.easy));
      expect(plan.blueprint.topicHint, contains('Modern History'));
    });

    test(
        'ranks candidate questions applying boosts for weak topics and penalty for recent exposures',
        () {
      final q1 = QuizQuestion(
        id: 'q_history_weak',
        question: 'History question 1',
        options: const [
          QuizOption(id: '0', text: 'A'),
          QuizOption(id: '1', text: 'B')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'History',
      );
      final q2 = QuizQuestion(
        id: 'q_history_recent',
        question: 'History question 2',
        options: const [
          QuizOption(id: '0', text: 'A'),
          QuizOption(id: '1', text: 'B')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'History',
      );
      final q3 = QuizQuestion(
        id: 'q_polity_strong',
        question: 'Polity question',
        options: const [
          QuizOption(id: '0', text: 'A'),
          QuizOption(id: '1', text: 'B')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'Polity',
      );

      final profile = LearnerProfile(
        learnerId: 'learner_1',
        topicPerformance: {
          'History': TopicMastery(
            topic: 'History',
            attempts: 5,
            correct: 1,
            incorrect: 4,
            accuracy: 0.20,
            masteryScore: 0.25,
          ),
          'Polity': TopicMastery(
            topic: 'Polity',
            attempts: 10,
            correct: 9,
            incorrect: 1,
            accuracy: 0.90,
            masteryScore: 0.85,
            confidence: 0.70,
          ),
        },
      );

      final ranked = strategy.rankQuestions(
        candidates: [q3, q2, q1],
        profile: profile,
        recentQuestionIds: ['q_history_recent'],
      );

      // q_history_weak should be ranked first because it is in a weak topic and not recently exposed
      expect(ranked.first.id, equals('q_history_weak'));
      // q_history_recent should be penalized for recent exposure
      expect(ranked.last.id, equals('q_history_recent'));
    });
  });

  group('Phase 8D: StudyNextEngine Prioritization Tests', () {
    const engine = StudyNextEngine();

    test('Priority 1: recommends overdue spaced review if due items exist', () {
      final dueItem = ReviewScheduleItem(
        id: 'rev_1',
        topic: 'Fundamental Rights',
        nextReviewAt: DateTime.now().subtract(const Duration(hours: 1)),
        lastAttemptAt: DateTime.now().subtract(const Duration(days: 2)),
        documentId: 'doc_law',
        pageNumber: 3,
      );

      final profile = LearnerProfile(
        learnerId: 'user_1',
        totalAssessments: 1,
        totalQuestionsAttempted: 5,
        totalCorrect: 3,
        totalIncorrect: 2,
        overallAccuracy: 0.60,
      );

      final next = engine.recommendNext(
        profile: profile,
        dueReviewItems: [dueItem],
      );

      expect(next.actionType, equals(StudyNextActionType.reviewDue));
      expect(next.targetTopic, equals('Fundamental Rights'));
      expect(next.hasDeepLink, isTrue);
      expect(next.deepLinkRequest?.pageNumber, equals(3));
    });

    test('Priority 2: recommends remediating weak topic when accuracy is zero',
        () {
      final profile = LearnerProfile(
        learnerId: 'user_2',
        totalAssessments: 1,
        totalQuestionsAttempted: 5,
        totalCorrect: 2,
        totalIncorrect: 3,
        overallAccuracy: 0.40,
        topicPerformance: {
          'Taxation': TopicMastery(
            topic: 'Taxation',
            attempts: 3,
            correct: 0,
            incorrect: 3,
            accuracy: 0.0,
            masteryScore: 0.20,
            pageNumbers: const [12],
            documentId: 'doc_economy',
          ),
        },
      );

      final next = engine.recommendNext(profile: profile);
      expect(next.actionType, equals(StudyNextActionType.remedyWeakTopic));
      expect(next.targetTopic, equals('Taxation'));
      expect(next.hasDeepLink, isTrue);
      expect(next.deepLinkRequest?.pageNumber, equals(12));
    });

    test('Priority 6: recommends starting first assessment for empty profile',
        () {
      final emptyProfile = LearnerProfile.empty();
      final next = engine.recommendNext(profile: emptyProfile);
      expect(next.actionType, equals(StudyNextActionType.startFirstAssessment));
    });
  });

  group('Phase 8D: LearnerProfileEngine Lifecycle & Integration Tests', () {
    const profileEngine = LearnerProfileEngine();

    test(
        'progressively updates learner profile across multiple assessments with trend detection',
        () {
      var profile = LearnerProfile.empty(learnerId: 'learner_pilot');

      final q1 = QuizQuestion(
        id: 'q1',
        question: 'Polity question 1',
        options: const [
          QuizOption(id: '0', text: 'A'),
          QuizOption(id: '1', text: 'B')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'Polity',
      );
      final q2 = QuizQuestion(
        id: 'q2',
        question: 'History question 1',
        options: const [
          QuizOption(id: '0', text: 'A'),
          QuizOption(id: '1', text: 'B')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'History',
      );

      final quiz = Quiz(
        id: 'quiz_session_1',
        title: 'Mixed Assessment',
        questions: [q1, q2],
        sourceDocumentId: 'doc_upsc',
      );

      // Session 1: q1 correct (Polity 100%), q2 incorrect (History 0%)
      final states1 = <String, InteractiveQuestionState>{
        'q1': InteractiveQuestionState(
          question: q1,
          selectedOptionIndices: const {0},
          status: AnswerStatus.correct,
          pageNumber: 2,
        ),
        'q2': InteractiveQuestionState(
          question: q2,
          selectedOptionIndices: const {1},
          status: AnswerStatus.incorrect,
          pageNumber: 8,
        ),
      };

      final perf1 = AssessmentPerformance(
        totalQuestions: 2,
        answeredQuestions: 2,
        correctAnswers: 1,
        incorrectAnswers: 1,
        unansweredQuestions: 0,
        score: 1.0,
        maxScore: 2.0,
        percentage: 50.0,
        accuracyByTopic: {'Polity': 1.0, 'History': 0.0},
        weakTopics: const ['History'],
        strongTopics: const ['Polity'],
        incorrectQuestionIds: const ['q2'],
      );

      profile = profileEngine.updateProfile(
        currentProfile: profile,
        quiz: quiz,
        performance: perf1,
        questionStates: states1,
      );

      expect(profile.totalAssessments, equals(1));
      expect(profile.totalQuestionsAttempted, equals(2));
      expect(profile.totalCorrect, equals(1));
      expect(profile.overallAccuracy, equals(0.50));
      expect(profile.weakTopics, contains('History'));
      expect(profile.topicPerformance['History']?.accuracy, equals(0.0));
      expect(profile.topicPerformance['Polity']?.accuracy, equals(1.0));

      // Session 2: Retest History with 100% correct -> Trend should switch to improving
      final states2 = <String, InteractiveQuestionState>{
        'q2': InteractiveQuestionState(
          question: q2,
          selectedOptionIndices: const {0},
          status: AnswerStatus.correct,
          pageNumber: 8,
        ),
      };
      final quiz2 = Quiz(
        id: 'quiz_session_2',
        title: 'History Retest',
        questions: [q2],
        sourceDocumentId: 'doc_upsc',
      );
      final perf2 = AssessmentPerformance(
        totalQuestions: 1,
        answeredQuestions: 1,
        correctAnswers: 1,
        incorrectAnswers: 0,
        unansweredQuestions: 0,
        score: 1.0,
        maxScore: 1.0,
        percentage: 100.0,
        accuracyByTopic: {'History': 1.0},
      );

      profile = profileEngine.updateProfile(
        currentProfile: profile,
        quiz: quiz2,
        performance: perf2,
        questionStates: states2,
      );

      expect(profile.totalAssessments, equals(2));
      expect(profile.totalQuestionsAttempted, equals(3));
      expect(profile.totalCorrect, equals(2));
      expect(profile.overallAccuracy, closeTo(0.667, 0.01));
      expect(profile.topicPerformance['History']?.trend,
          equals(MasteryTrend.improving));
      expect(profile.topicPerformance['History']?.retention,
          equals(RetentionSignal.improving));
    });
  });

  group('Phase 8D: Repository Tests', () {
    test(
        'InMemoryLearnerProfileRepository saves, retrieves and clears profiles',
        () async {
      final repo = InMemoryLearnerProfileRepository();
      expect(await repo.getProfile('learner_a'), isNull);

      final profile = LearnerProfile.empty(learnerId: 'learner_a');
      await repo.saveProfile(profile);

      final retrieved = await repo.getProfile('learner_a');
      expect(retrieved?.learnerId, equals('learner_a'));

      await repo.deleteProfile('learner_a');
      expect(await repo.getProfile('learner_a'), isNull);
    });

    test('InMemoryReviewScheduleRepository saves and queries due items',
        () async {
      final repo = InMemoryReviewScheduleRepository();
      final now = DateTime.now();
      final item = ReviewScheduleItem(
        id: 'sched_1',
        topic: 'Geography',
        nextReviewAt: now.subtract(const Duration(hours: 1)),
        lastAttemptAt: now.subtract(const Duration(days: 1)),
      );

      await repo.saveItem(item, learnerId: 'user_1');
      final all = await repo.getItems(learnerId: 'user_1');
      expect(all.length, equals(1));

      final due = await repo.getDueItems(learnerId: 'user_1');
      expect(due.length, equals(1));
      expect(due.first.id, equals('sched_1'));
    });
  });
}
