import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/coordinator/application_coordinator.dart';
import 'package:quizforge_ai/src/presentation/widgets/adaptive/learner_mastery_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/adaptive/practice_weak_areas_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/adaptive/review_schedule_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/adaptive/study_next_hero_card.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

import 'support/mock_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApplicationCoordinator coordinator;

  setUp(() async {
    coordinator = await buildMockCoordinator();
  });

  group('Phase 8D: ApplicationCoordinator Adaptive Workflows', () {
    test('getLearnerProfile returns empty profile initially', () async {
      final profile =
          await coordinator.getLearnerProfile(learnerId: 'user_test');
      expect(profile.learnerId, equals('user_test'));
      expect(profile.isEmpty, isTrue);
      expect(profile.totalAssessments, equals(0));
    });

    test(
        'updateLearnerProfileAfterAssessment updates metrics and registers review items',
        () async {
      // 1. Prepare Quiz and Session in repositories
      final q1 = QuizQuestion(
        id: 'q1',
        question: 'What is Article 21?',
        options: const [
          QuizOption(id: '0', text: 'Life'),
          QuizOption(id: '1', text: 'Tax')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'Constitutional Law',
        pageReference: 4,
      );
      final q2 = QuizQuestion(
        id: 'q2',
        question: 'What is Fiscal Deficit?',
        options: const [
          QuizOption(id: '0', text: 'Borrowing'),
          QuizOption(id: '1', text: 'Surplus')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'Economics',
        pageReference: 12,
      );

      final quiz = Quiz(
        id: 'quiz_adapt_1',
        title: 'Diagnostic Test',
        questions: [q1, q2],
        sourceDocumentId: 'doc_1',
      );
      await coordinator.quizRepository.saveQuiz(quiz);

      final now = DateTime.now();
      final session = QuizSession(
        sessionId: 'session_adapt_1',
        quizId: 'quiz_adapt_1',
        startedAt: now,
        lastUpdatedAt: now,
        status: QuizSessionStatus.inProgress,
        answers: const [],
      );
      await coordinator.quizSessionRepository.saveSession(session);

      // 2. Answering: q1 correct, q2 incorrect
      final states = <String, InteractiveQuestionState>{
        'q1': InteractiveQuestionState(
          question: q1,
          selectedOptionIndices: const {0},
          status: AnswerStatus.correct,
          pageNumber: 4,
        ),
        'q2': InteractiveQuestionState(
          question: q2,
          selectedOptionIndices: const {1},
          status: AnswerStatus.incorrect,
          pageNumber: 12,
        ),
      };

      final perf = AssessmentPerformance(
        totalQuestions: 2,
        answeredQuestions: 2,
        correctAnswers: 1,
        incorrectAnswers: 1,
        unansweredQuestions: 0,
        score: 1.0,
        maxScore: 2.0,
        percentage: 50.0,
        accuracyByTopic: {'Constitutional Law': 1.0, 'Economics': 0.0},
        weakTopics: const ['Economics'],
        strongTopics: const ['Constitutional Law'],
        incorrectQuestionIds: const ['q2'],
      );

      final updatedProfile =
          await coordinator.updateLearnerProfileAfterAssessment(
        sessionId: 'session_adapt_1',
        performance: perf,
        questionStates: states,
        learnerId: 'user_test',
      );

      expect(updatedProfile.totalAssessments, equals(1));
      expect(updatedProfile.totalQuestionsAttempted, equals(2));
      expect(updatedProfile.totalCorrect, equals(1));
      expect(updatedProfile.weakTopics, contains('Economics'));
      expect(updatedProfile.topicPerformance['Constitutional Law']?.accuracy,
          equals(1.0));

      // 3. Verify Review items registered for weak topic question q2
      final reviewItems = await coordinator.reviewScheduleRepository
          .getItems(learnerId: 'user_test');
      expect(reviewItems.length, equals(1));
      expect(reviewItems.first.topic, equals('Economics'));
      expect(reviewItems.first.questionId, equals('q2'));
      expect(reviewItems.first.pageNumber, equals(12));
    });

    test('getStudyNextRecommendation produces actionable deterministic advice',
        () async {
      final rec =
          await coordinator.getStudyNextRecommendation(learnerId: 'user_new');
      expect(rec.actionType, equals(StudyNextActionType.startFirstAssessment));
      expect(rec.title, contains('First Assessment'));
    });

    test('getAdaptiveRemedialPlan builds complete remedial plan', () async {
      final q1 = QuizQuestion(
        id: 'q1',
        question: 'Polity',
        options: const [
          QuizOption(id: '0', text: 'A'),
          QuizOption(id: '1', text: 'B')
        ],
        correctAnswerIndex: 0,
        marks: 1.0,
        topic: 'Polity',
      );
      final quiz = Quiz(
          id: 'quiz_plan_1',
          title: 'Plan Quiz',
          questions: [q1],
          sourceDocumentId: 'doc_p1');
      await coordinator.quizRepository.saveQuiz(quiz);
      final now = DateTime.now();
      final session = QuizSession(
        sessionId: 'sess_plan_1',
        quizId: 'quiz_plan_1',
        startedAt: now,
        lastUpdatedAt: now,
        status: QuizSessionStatus.completed,
        answers: const [],
      );
      await coordinator.quizSessionRepository.saveSession(session);

      final states = <String, InteractiveQuestionState>{
        'q1': InteractiveQuestionState(
            question: q1, status: AnswerStatus.incorrect, pageNumber: 2),
      };
      final perf = AssessmentPerformance(
        totalQuestions: 1,
        answeredQuestions: 1,
        correctAnswers: 0,
        incorrectAnswers: 1,
        unansweredQuestions: 0,
        score: 0.0,
        maxScore: 1.0,
        percentage: 0.0,
        accuracyByTopic: {'Polity': 0.0},
        weakTopics: const ['Polity'],
        incorrectQuestionIds: const ['q1'],
      );

      final remedialPlan = await coordinator.getAdaptiveRemedialPlan(
        sessionId: 'sess_plan_1',
        performance: perf,
        questionStates: states,
        learnerId: 'user_plan',
      );

      expect(remedialPlan.priorityTopics, contains('Polity'));
      expect(remedialPlan.retryQuestions, contains('q1'));
      expect(remedialPlan.hasSourceReviews, isTrue);
    });
  });

  group('Phase 8D: Adaptive Learning Presentation Widgets Tests', () {
    testWidgets(
        'StudyNextHeroCard renders hero details and triggers action callbacks',
        (tester) async {
      var primaryTapped = false;
      ReaderDeepLinkRequest? receivedLink;

      final rec = StudyNextRecommendation(
        actionType: StudyNextActionType.remedyWeakTopic,
        title: 'Remediate Weak Area: Economics',
        description: 'You scored 0% on Economics in your last test.',
        targetTopic: 'Economics',
        documentId: 'doc_eco',
        pageNumber: 7,
        deepLinkRequest: ReaderDeepLinkRequest(
          documentId: 'doc_eco',
          pageNumber: 7,
          source: 'study_next',
        ),
        recommendedDifficulty: QuizDifficulty.easy,
        rationale: 'Review source material on page 7 before retrying.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyNextHeroCard(
              recommendation: rec,
              onPrimaryAction: () => primaryTapped = true,
              onOpenSource: (link) => receivedLink = link,
            ),
          ),
        ),
      );

      expect(find.text('STUDY NEXT'), findsOneWidget);
      expect(find.text('Remediate Weak Area: Economics'), findsOneWidget);
      expect(find.text('Study in Reader (p. 7)'), findsOneWidget);

      await tester.tap(find.text('Study in Reader (p. 7)'));
      await tester.pumpAndSettle();
      expect(receivedLink?.pageNumber, equals(7));

      await tester.tap(find.text('Start Adaptive Practice'));
      await tester.pumpAndSettle();
      expect(primaryTapped, isTrue);
    });

    testWidgets(
        'LearnerMasteryCard displays mastery bars, weak chips and metrics',
        (tester) async {
      final profile = LearnerProfile(
        learnerId: 'user_ui',
        totalAssessments: 3,
        totalQuestionsAttempted: 15,
        totalCorrect: 11,
        totalIncorrect: 4,
        overallAccuracy: 0.733,
        overallMastery: 0.70,
        topicPerformance: {
          'Polity': TopicMastery(
            topic: 'Polity',
            attempts: 10,
            correct: 9,
            incorrect: 1,
            accuracy: 0.90,
            masteryScore: 0.85,
            confidence: 0.70,
            trend: MasteryTrend.improving,
          ),
          'Taxation': TopicMastery(
            topic: 'Taxation',
            attempts: 5,
            correct: 2,
            incorrect: 3,
            accuracy: 0.40,
            masteryScore: 0.38,
            confidence: 0.50,
            trend: MasteryTrend.declining,
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnerMasteryCard(profile: profile),
          ),
        ),
      );

      expect(find.text('Knowledge & Mastery Profile'), findsOneWidget);
      expect(find.text('70% Mastery'), findsOneWidget);
      expect(find.text('Polity'), findsOneWidget);
      expect(find.text('MASTERED'), findsOneWidget);
      expect(find.text('Taxation'), findsOneWidget);
      expect(find.text('WEAK'), findsOneWidget);
    });

    testWidgets('PracticeWeakAreasCard renders weak topic chips and button',
        (tester) async {
      var practiceStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticeWeakAreasCard(
              weakTopics: const ['Ancient History', 'Macroeconomics'],
              recommendedDifficulty: QuizDifficulty.easy,
              onStartPractice: () => practiceStarted = true,
            ),
          ),
        ),
      );

      expect(find.text('Practice Weak Areas'), findsOneWidget);
      expect(find.text('Ancient History'), findsOneWidget);
      expect(find.text('Macroeconomics'), findsOneWidget);
      expect(find.text('Start Adaptive Weak Area Practice'), findsOneWidget);

      await tester.tap(find.text('Start Adaptive Weak Area Practice'));
      await tester.pumpAndSettle();
      expect(practiceStarted, isTrue);
    });

    testWidgets(
        'ReviewScheduleCard displays due review items and allows review triggering',
        (tester) async {
      final now = DateTime.now();
      final item = ReviewScheduleItem(
        id: 'rev_ui_1',
        topic: 'Judicial Review',
        nextReviewAt: now.subtract(const Duration(hours: 2)),
        lastAttemptAt: now.subtract(const Duration(days: 1)),
        pageNumber: 9,
        documentId: 'doc_law',
      );

      ReviewScheduleItem? reviewedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewScheduleCard(
              items: [item],
              onReviewItem: (i) => reviewedItem = i,
            ),
          ),
        ),
      );

      expect(find.text('Spaced Review Schedule'), findsOneWidget);
      expect(find.text('1 DUE'), findsOneWidget);
      expect(find.text('Judicial Review'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(reviewedItem?.topic, equals('Judicial Review'));
    });
  });
}
