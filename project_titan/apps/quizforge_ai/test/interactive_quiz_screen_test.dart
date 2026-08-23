import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import 'package:quizforge_ai/src/coordinator/application_coordinator.dart';
import 'package:quizforge_ai/src/presentation/providers/interactive_quiz_controller.dart';
import 'package:quizforge_ai/src/presentation/widgets/quiz/immediate_feedback_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/quiz/interactive_option_tile.dart';
import 'package:quizforge_ai/src/presentation/widgets/quiz/question_progress_strip.dart';
import 'package:quizforge_ai/src/presentation/widgets/result/remedial_study_card.dart';

class FakePdfRepository implements PdfRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuizGenerationRepository implements QuizGenerationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuizSessionRepository implements QuizSessionRepository {
  final Map<String, QuizSession> sessions = {};

  @override
  Future<QuizSession> createSession(Quiz quiz,
      {SessionConfiguration configuration =
          const SessionConfiguration.standard()}) async {
    final session = QuizSession(
      sessionId: 'session_${quiz.id}',
      quizId: quiz.id,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      answers:
          quiz.questions.map((q) => QuestionAttempt.unanswered(q.id)).toList(),
    );
    sessions[session.sessionId] = session;
    return session;
  }

  @override
  Future<QuizSession?> loadSession(String sessionId) async =>
      sessions[sessionId];

  @override
  Future<void> saveSession(QuizSession session) async {
    sessions[session.sessionId] = session;
  }

  @override
  Future<QuizResultSummary> completeSession(String sessionId, Quiz quiz) async {
    final session = sessions[sessionId]!;
    final summary = QuizResultSummary(
      totalQuestions: quiz.questions.length,
      attempted: session.answers.where((a) => a.isAnswered).length,
      correct: 1,
      wrong: 1,
      unanswered: 0,
      score: 2.0,
      maxScore: 4.0,
      percentage: 50.0,
      timeTaken: const Duration(minutes: 2),
    );
    return summary;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuizRepository implements QuizRepository {
  final Map<String, Quiz> quizzes = {};

  @override
  Future<Quiz?> loadQuiz(String quizId) async => quizzes[quizId];

  @override
  Future<void> saveQuiz(Quiz quiz) async {
    quizzes[quiz.id] = quiz;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 8C: Interactive Quiz Controller & Remedial Study Loop Tests',
      () {
    late ApplicationCoordinator coordinator;
    late FakeQuizSessionRepository sessionRepo;
    late FakeQuizRepository quizRepo;
    late InMemoryReaderDeepLinkHandler readerHandler;
    late Quiz testQuiz;
    late QuizSession testSession;

    setUp(() async {
      sessionRepo = FakeQuizSessionRepository();
      quizRepo = FakeQuizRepository();
      readerHandler = InMemoryReaderDeepLinkHandler();

      coordinator = ApplicationCoordinator(
        pdfRepository: FakePdfRepository(),
        quizGenerationRepository: FakeQuizGenerationRepository(),
        quizSessionRepository: sessionRepo,
        quizRepository: quizRepo,
        readerDeepLinkHandler: readerHandler,
      );

      testQuiz = Quiz(
        id: 'quiz_demo',
        title: 'Fundamental Rights & Preamble',
        sourceDocumentId: 'doc_constitution_pdf',
        questions: [
          QuizQuestion(
            id: 'q_01',
            question:
                'Which Article of the Constitution guarantees Equality before Law?',
            options: const [
              QuizOption(id: '0', text: 'Article 14'),
              QuizOption(id: '1', text: 'Article 19'),
              QuizOption(id: '2', text: 'Article 21'),
              QuizOption(id: '3', text: 'Article 32'),
            ],
            correctAnswerIndex: 0,
            explanation:
                'Article 14 guarantees equality before the law and equal protection of laws.',
            topic: 'Fundamental Rights',
            marks: 2.0,
            negativeMarks: 0.66,
            pageReference: 4,
          ),
          QuizQuestion(
            id: 'q_02',
            question:
                'Is the Preamble considered an integral part of the Indian Constitution?',
            options: const [
              QuizOption(id: '0', text: 'True'),
              QuizOption(id: '1', text: 'False'),
            ],
            correctAnswerIndex: 0,
            explanation:
                'The Kesavananda Bharati case established that the Preamble is an integral part.',
            topic: 'Preamble',
            marks: 2.0,
            negativeMarks: 0.66,
            pageReference: 2,
          ),
        ],
      );

      await quizRepo.saveQuiz(testQuiz);
      testSession = await sessionRepo.createSession(testQuiz);
    });

    test(
        '1. InteractiveQuizController initializes, selects options, and evaluates immediately',
        () async {
      final controller = InteractiveQuizController(coordinator: coordinator);

      controller.initialize(quiz: testQuiz, session: testSession);

      expect(controller.state.totalQuestions, 2);
      expect(controller.state.currentIndex, 0);
      expect(controller.state.currentQuestion?.id, 'q_01');
      expect(controller.state.currentQuestionState?.status,
          AnswerStatus.unanswered);

      // Select Option A (index 0)
      controller.selectOption(0);
      expect(
          controller.state.currentQuestionState?.status, AnswerStatus.selected);
      expect(controller.state.currentQuestionState?.isSelected, isTrue);
      expect(controller.state.currentQuestionState?.isSubmitted, isFalse);

      // Submit answer
      await controller.submitCurrentAnswer();
      expect(
          controller.state.currentQuestionState?.status, AnswerStatus.correct);
      expect(controller.state.currentQuestionState?.isSubmitted, isTrue);
      expect(controller.state.currentQuestionState?.isCorrect, isTrue);

      // Navigate to question 2
      controller.nextQuestion();
      expect(controller.state.currentIndex, 1);
      expect(controller.state.currentQuestion?.id, 'q_02');

      // Select Option B (index 1, incorrect for q_02)
      controller.selectOption(1);
      await controller.submitCurrentAnswer();
      expect(controller.state.currentQuestionState?.status,
          AnswerStatus.incorrect);
      expect(controller.state.currentQuestionState?.isCorrect, isFalse);
    });

    test(
        '2. InteractiveQuizController completes assessment and produces remedial recommendations',
        () async {
      final controller = InteractiveQuizController(coordinator: coordinator);
      controller.initialize(quiz: testQuiz, session: testSession);

      // Q1: Correct
      controller.selectOption(0);
      await controller.submitCurrentAnswer();

      // Q2: Incorrect
      controller.nextQuestion();
      controller.selectOption(1);
      await controller.submitCurrentAnswer();

      // Complete Assessment
      final performance = await controller.completeAssessment();
      expect(performance, isNotNull);
      expect(performance!.totalQuestions, 2);
      expect(performance.correctAnswers, 1);
      expect(performance.incorrectAnswers, 1);

      // Recommendations should contain Preamble (0% accuracy)
      expect(controller.state.recommendations.isNotEmpty, isTrue);
      final rec = controller.state.recommendations.first;
      expect(rec.topic, 'Preamble');
      expect(rec.primaryPageNumber, 2);
      expect(rec.recommendedAction, RemedialActionType.reviewSource);
    });

    test('3. Deep-link navigation dispatches through ReaderDeepLinkHandler',
        () async {
      final controller = InteractiveQuizController(coordinator: coordinator);
      controller.initialize(quiz: testQuiz, session: testSession);

      final req = ReaderDeepLinkRequest(
        documentId: 'doc_constitution_pdf',
        pageNumber: 4,
        chunkId: 'chk_14',
      );

      final result = await controller.studySourceInReader(req);
      expect(result, isTrue);
      expect(readerHandler.handledRequests.length, 1);
      expect(readerHandler.handledRequests.first.pageNumber, 4);
    });

    test(
        '4. ApplicationCoordinator.createRetrySession generates filtered quiz for incorrect questions',
        () async {
      // First attempt session
      final attemptedSession =
          sessionRepo.sessions[testSession.sessionId]!.copyWith(
        answers: [
          const QuestionAttempt(
            questionId: 'q_01',
            selectedOptionId: '0', // Correct
            isAnswered: true,
          ),
          const QuestionAttempt(
            questionId: 'q_02',
            selectedOptionId: '1', // Incorrect (correct is 0)
            isAnswered: true,
          ),
        ],
      );
      await sessionRepo.saveSession(attemptedSession);

      final retrySession = await coordinator.createRetrySession(
        originalSessionId: attemptedSession.sessionId,
        retryMode: RetryMode.incorrect,
      );

      expect(retrySession, isNotNull);
      expect(retrySession.sessionId, isNot(equals(attemptedSession.sessionId)));

      final retryQuiz = await quizRepo.loadQuiz(retrySession.quizId);
      expect(retryQuiz, isNotNull);
      expect(retryQuiz!.questions.length, 1);
      expect(
          retryQuiz.questions.first.id, 'q_02'); // Only the incorrect question
    });
  });

  group('Phase 8C: Interactive Assessment Widget Tests', () {
    testWidgets(
        '5. InteractiveOptionTile renders states correctly and triggers taps',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveOptionTile(
              optionIndex: 0,
              optionText: 'Article 14',
              isSelected: false,
              isEvaluated: false,
              isCorrectOption: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Article 14'), findsOneWidget);

      await tester.tap(find.byType(InteractiveOptionTile));
      await tester.pump();
      expect(tapped, isTrue);

      // Render evaluated state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveOptionTile(
              optionIndex: 0,
              optionText: 'Article 14',
              isSelected: true,
              isEvaluated: true,
              isCorrectOption: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
        '6. ImmediateFeedbackCard displays explanation and triggers reader study action',
        (tester) async {
      var studied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImmediateFeedbackCard(
              isCorrect: true,
              explanation: 'Article 14 guarantees equality.',
              pageNumber: 4,
              onStudySource: () => studied = true,
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
      expect(find.text('Article 14 guarantees equality.'), findsOneWidget);

      await tester.tap(find.text('Study Source in Reader'));
      await tester.pump();
      expect(studied, isTrue);
    });

    testWidgets('7. QuestionProgressStrip renders numbers and captures taps',
        (tester) async {
      var tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionProgressStrip(
              currentIndex: 0,
              questions: [
                QuizQuestion(
                  id: 'q1',
                  question: 'Q1',
                  options: const [
                    QuizOption(id: '0', text: 'A'),
                    QuizOption(id: '1', text: 'B')
                  ],
                  correctAnswerIndex: 0,
                ),
                QuizQuestion(
                  id: 'q2',
                  question: 'Q2',
                  options: const [
                    QuizOption(id: '0', text: 'A'),
                    QuizOption(id: '1', text: 'B')
                  ],
                  correctAnswerIndex: 1,
                ),
              ],
              questionStates: {
                'q1': InteractiveQuestionState(
                  question: QuizQuestion(
                    id: 'q1',
                    question: 'Q1',
                    options: const [
                      QuizOption(id: '0', text: 'A'),
                      QuizOption(id: '1', text: 'B')
                    ],
                    correctAnswerIndex: 0,
                  ),
                  status: AnswerStatus.correct,
                ),
              },
              onQuestionTapped: (idx) => tappedIndex = idx,
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(tappedIndex, 1);
    });

    testWidgets(
        '8. RemedialStudyCard renders recommendations and triggers actions',
        (tester) async {
      var studyTriggered = false;
      var retryTriggered = false;

      final rec = RemedialStudyRecommendation(
        id: 'rec_1',
        documentId: 'doc_1',
        topic: 'Fundamental Rights',
        pageNumbers: [4],
        reason: 'Accuracy was 25%.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemedialStudyCard(
              recommendations: [rec],
              onStudySource: (_) => studyTriggered = true,
              onRetryIncorrect: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Remedial Study Loop'), findsOneWidget);
      expect(find.text('Fundamental Rights'), findsOneWidget);
      expect(find.text('Study in Reader (p. 4)'), findsOneWidget);
      expect(find.text('Retry Incorrect Questions'), findsOneWidget);

      await tester.tap(find.text('Study in Reader (p. 4)'));
      await tester.pump();
      expect(studyTriggered, isTrue);

      await tester.tap(find.text('Retry Incorrect Questions'));
      await tester.pump();
      expect(retryTriggered, isTrue);
    });
  });
}
