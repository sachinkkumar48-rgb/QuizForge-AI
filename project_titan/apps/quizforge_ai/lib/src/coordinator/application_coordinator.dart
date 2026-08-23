import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

import '../exceptions/application_exception.dart';
import '../states/application_state.dart';
import '../states/quiz_workflow_state.dart';

/// Coordinator orchestrating the complete QuizForge AI application workflow across domain modules.
class ApplicationCoordinator {
  final PdfRepository _pdfRepository;
  final QuizGenerationRepository _quizGenerationRepository;
  final QuizSessionRepository _quizSessionRepository;
  final QuizRepository _quizRepository;
  final ReaderDeepLinkHandler _readerDeepLinkHandler;

  ApplicationState _state = const ApplicationState.idle();

  ApplicationCoordinator({
    required PdfRepository pdfRepository,
    required QuizGenerationRepository quizGenerationRepository,
    required QuizSessionRepository quizSessionRepository,
    required QuizRepository quizRepository,
    ReaderDeepLinkHandler? readerDeepLinkHandler,
  })  : _pdfRepository = pdfRepository,
        _quizGenerationRepository = quizGenerationRepository,
        _quizSessionRepository = quizSessionRepository,
        _quizRepository = quizRepository,
        _readerDeepLinkHandler =
            readerDeepLinkHandler ?? InMemoryReaderDeepLinkHandler();

  /// Returns the current immutable application state.
  ApplicationState get state => _state;

  /// Returns the configured [ReaderDeepLinkHandler].
  ReaderDeepLinkHandler get readerDeepLinkHandler => _readerDeepLinkHandler;

  /// Returns the configured [QuizRepository].
  QuizRepository get quizRepository => _quizRepository;

  /// Returns the configured [QuizSessionRepository].
  QuizSessionRepository get quizSessionRepository => _quizSessionRepository;

  /// Returns the configured [PdfRepository].
  PdfRepository get pdfRepository => _pdfRepository;

  /// Returns the configured [QuizGenerationRepository].
  QuizGenerationRepository get quizGenerationRepository =>
      _quizGenerationRepository;

  /// Navigates to a source document/page/chunk in TITAN Reader via shared navigation contract.
  Future<bool> navigateToReaderSource(ReaderDeepLinkRequest request) async {
    try {
      return await _readerDeepLinkHandler.openReaderToSource(request);
    } catch (_) {
      return false;
    }
  }

  /// Creates a new retry session filtered to either incorrect questions, unanswered questions,
  /// or marked review questions from an existing session.
  Future<QuizSession> createRetrySession({
    required String originalSessionId,
    RetryMode retryMode = RetryMode.incorrect,
    SessionConfiguration sessionConfig = const SessionConfiguration.standard(),
  }) async {
    _state = const ApplicationState.loading();
    try {
      final originalSession =
          await _quizSessionRepository.loadSession(originalSessionId);
      if (originalSession == null) {
        throw ApplicationException(
          'Original session [$originalSessionId] not found.',
          code: 'SESSION_NOT_FOUND',
        );
      }

      final originalQuiz =
          await _quizRepository.loadQuiz(originalSession.quizId);
      if (originalQuiz == null) {
        throw ApplicationException(
          'Original quiz [${originalSession.quizId}] not found.',
          code: 'QUIZ_NOT_FOUND',
        );
      }

      final targetQuestions = <QuizQuestion>[];
      for (final q in originalQuiz.questions) {
        final attempt = originalSession.answers.firstWhere(
          (a) => a.questionId == q.id,
          orElse: () => QuestionAttempt.unanswered(q.id),
        );

        if (retryMode == RetryMode.incorrect) {
          if (attempt.isAnswered &&
              attempt.selectedOptionId != '${q.correctAnswerIndex}') {
            targetQuestions.add(q);
          }
        } else if (retryMode == RetryMode.unanswered) {
          if (!attempt.isAnswered) {
            targetQuestions.add(q);
          }
        } else if (retryMode == RetryMode.all) {
          targetQuestions.add(q);
        }
      }

      if (targetQuestions.isEmpty) {
        throw ApplicationException(
          'No matching questions found for retry mode [${retryMode.name}].',
          code: 'NO_RETRY_QUESTIONS',
        );
      }

      final retryQuiz = originalQuiz.copyWith(
        id: 'retry_${originalQuiz.id}_${DateTime.now().millisecondsSinceEpoch}',
        title:
            '${originalQuiz.title} (${retryMode == RetryMode.incorrect ? "Retry Incorrect" : "Retry"})',
        questions: targetQuestions,
      );

      await _quizRepository.saveQuiz(retryQuiz);
      final newSession = await _quizSessionRepository.createSession(
        retryQuiz,
        configuration: sessionConfig,
      );

      _state = ApplicationState.ready(newSession);
      return newSession;
    } catch (e, st) {
      final appEx = _mapToApplicationException(e, st);
      _state = ApplicationState.error(appEx.message, appEx);
      throw appEx;
    }
  }

  /// Executes the complete PDF to Quiz Session pipeline flow.
  ///
  /// Workflow:
  /// 1. Import PDF ([filePath]) via [PdfRepository]
  /// 2. Extract text & chunks
  /// 3. Generate quiz via [QuizGenerationRepository]
  /// 4. Create quiz session via [QuizSessionRepository]
  /// 5. Return [QuizSession]
  Future<QuizSession> createQuizSessionFromPdf({
    required String filePath,
    QuizCategory category = QuizCategory.upsc,
    QuizDifficulty difficulty = QuizDifficulty.medium,
    QuizLanguage language = QuizLanguage.english,
    int questionsPerChunk = 5,
    SessionConfiguration sessionConfig = const SessionConfiguration.standard(),
  }) async {
    return importPdf(
      filePath: filePath,
      category: category,
      difficulty: difficulty,
      language: language,
      questionsPerChunk: questionsPerChunk,
      sessionConfig: sessionConfig,
    );
  }

  /// Imports a PDF and creates a quiz session while reporting presentation workflow stages.
  Future<QuizSession> importPdf({
    required String filePath,
    QuizCategory category = QuizCategory.upsc,
    QuizDifficulty difficulty = QuizDifficulty.medium,
    QuizLanguage language = QuizLanguage.english,
    int questionsPerChunk = 5,
    SessionConfiguration sessionConfig = const SessionConfiguration.standard(),
    void Function(QuizWorkflowStage stage)? onStageChanged,
  }) async {
    _state = const ApplicationState.loading();

    try {
      // Step 1: Import PDF Document
      onStageChanged?.call(QuizWorkflowStage.importingPdf);
      final importResult = await _pdfRepository.importPdf(filePath);
      final documentId = importResult.document.id;

      // Step 2: Ensure text extraction and chunk creation
      onStageChanged?.call(QuizWorkflowStage.extractingText);
      await _pdfRepository.extractText(documentId);
      onStageChanged?.call(QuizWorkflowStage.creatingChunks);
      await _pdfRepository.createChunks(documentId);

      // Step 3: Transition to Generating Quiz state & Generate Quiz via AI
      _state = const ApplicationState.generatingQuiz();
      onStageChanged?.call(QuizWorkflowStage.generatingQuiz);

      final genRequest = QuizGenerationRequest(
        documentId: documentId,
        category: category,
        difficulty: difficulty,
        language: language,
        questionsPerChunk: questionsPerChunk,
      );

      final genResult =
          await _quizGenerationRepository.generateQuiz(genRequest);

      // Step 4: Create Quiz Session
      onStageChanged?.call(QuizWorkflowStage.creatingSession);
      final session = await _quizSessionRepository.createSession(
        genResult.quiz,
        configuration: sessionConfig,
      );

      // Step 5: Transition to Ready state and return QuizSession
      _state = ApplicationState.ready(session);
      onStageChanged?.call(QuizWorkflowStage.ready);
      return session;
    } catch (e, st) {
      final appEx = _mapToApplicationException(e, st);
      _state = ApplicationState.error(appEx.message, appEx);
      throw appEx;
    }
  }

  /// Ingests a pre-processed [LearningDocument] from TITAN's document intelligence pipeline
  /// and generates an AI quiz session.
  Future<QuizSession> importLearningDocument({
    required LearningDocument document,
    QuizCategory category = QuizCategory.upsc,
    QuizDifficulty difficulty = QuizDifficulty.medium,
    QuizLanguage language = QuizLanguage.english,
    int questionsPerChunk = 5,
    SessionConfiguration sessionConfig = const SessionConfiguration.standard(),
    void Function(QuizWorkflowStage stage)? onStageChanged,
  }) async {
    _state = const ApplicationState.loading();

    try {
      // Step 1: Register document & chunks via AssessmentDocumentBridge
      onStageChanged?.call(QuizWorkflowStage.importingPdf);
      final pdfDoc = await AssessmentDocumentBridge.registerLearningDocument(
        document: document,
        pdfRepository: _pdfRepository,
      );

      // Step 2: Transition to Generating Quiz state & Generate Quiz via AI
      _state = const ApplicationState.generatingQuiz();
      onStageChanged?.call(QuizWorkflowStage.generatingQuiz);

      final genRequest = QuizGenerationRequest(
        documentId: pdfDoc.id,
        category: category,
        difficulty: difficulty,
        language: language,
        questionsPerChunk: questionsPerChunk,
      );

      final genResult =
          await _quizGenerationRepository.generateQuiz(genRequest);

      // Step 3: Create Quiz Session
      onStageChanged?.call(QuizWorkflowStage.creatingSession);
      final session = await _quizSessionRepository.createSession(
        genResult.quiz,
        configuration: sessionConfig,
      );

      // Step 4: Transition to Ready state and return QuizSession
      _state = ApplicationState.ready(session);
      onStageChanged?.call(QuizWorkflowStage.ready);
      return session;
    } catch (e, st) {
      final appEx = _mapToApplicationException(e, st);
      _state = ApplicationState.error(appEx.message, appEx);
      throw appEx;
    }
  }

  /// Generates a smart assessment directly from a [LearningDocument] using an [AssessmentBlueprint]
  /// and [AssessmentGenerator], enforcing strict source grounding and validation.
  Future<QuizSession> generateSmartAssessment({
    required LearningDocument document,
    required AssessmentBlueprint blueprint,
    required AssessmentGenerator assessmentGenerator,
    AssessmentCancellationToken? cancellationToken,
    SessionConfiguration sessionConfig = const SessionConfiguration.standard(),
    void Function(QuizWorkflowStage stage)? onStageChanged,
  }) async {
    _state = const ApplicationState.loading();

    try {
      cancellationToken?.throwIfCancelled();

      // Step 1: Register document & chunks into repository
      onStageChanged?.call(QuizWorkflowStage.importingPdf);
      final pdfDoc = await AssessmentDocumentBridge.registerLearningDocument(
        document: document,
        pdfRepository: _pdfRepository,
      );

      cancellationToken?.throwIfCancelled();

      // Step 2: Convert LearningDocumentChunks to AssessmentSources
      const sourceBridge = AssessmentSourceBridge();
      final sources = sourceBridge.fromLearningDocument(
        document: document,
        blueprint: blueprint,
      );

      // Step 3: Transition to Generating Quiz & invoke AssessmentGenerator
      _state = const ApplicationState.generatingQuiz();
      onStageChanged?.call(QuizWorkflowStage.generatingQuiz);

      final genRequest = AssessmentGenerationRequest(
        blueprint: blueprint.copyWith(documentId: pdfDoc.id),
        sources: sources,
        cancellationToken: cancellationToken,
      );

      final genResult =
          await assessmentGenerator.generateAssessment(genRequest);

      cancellationToken?.throwIfCancelled();

      // Persist quiz to repository
      await _quizRepository.saveQuiz(genResult.quiz);

      // Step 4: Create Quiz Session
      onStageChanged?.call(QuizWorkflowStage.creatingSession);
      final session = await _quizSessionRepository.createSession(
        genResult.quiz,
        configuration: sessionConfig,
      );

      // Step 5: Transition to Ready state and return QuizSession
      _state = ApplicationState.ready(session);
      onStageChanged?.call(QuizWorkflowStage.ready);
      return session;
    } catch (e, st) {
      final appEx = _mapToApplicationException(e, st);
      _state = ApplicationState.error(appEx.message, appEx);
      throw appEx;
    }
  }

  /// Attempts a question within an active session.
  Future<QuizSession> answerQuestion({
    required String sessionId,
    required String questionId,
    required String? selectedOptionId,
    Duration timeSpent = Duration.zero,
    required QuizSessionService sessionService,
  }) async {
    try {
      final session = await _quizSessionRepository.loadSession(sessionId);
      if (session == null) {
        throw ApplicationException(
          'Session [$sessionId] not found.',
          code: 'SESSION_NOT_FOUND',
        );
      }

      final quiz = await _quizRepository.loadQuiz(session.quizId);
      if (quiz == null) {
        throw ApplicationException(
          'Associated quiz [${session.quizId}] not found.',
          code: 'QUIZ_NOT_FOUND',
        );
      }

      final updatedSession = sessionService.answerQuestion(
        session,
        quiz,
        questionId,
        selectedOptionId,
        timeSpent: timeSpent,
      );

      await _quizSessionRepository.saveSession(updatedSession);
      _state = ApplicationState.ready(updatedSession);
      return updatedSession;
    } catch (e, st) {
      final appEx = _mapToApplicationException(e, st);
      _state = ApplicationState.error(appEx.message, appEx);
      throw appEx;
    }
  }

  /// Completes an active quiz session and generates the final evaluation result.
  Future<QuizResultSummary> completeSession({
    required String sessionId,
  }) async {
    try {
      final session = await _quizSessionRepository.loadSession(sessionId);
      if (session == null) {
        throw ApplicationException(
          'Session [$sessionId] not found.',
          code: 'SESSION_NOT_FOUND',
        );
      }

      final quiz = await _quizRepository.loadQuiz(session.quizId);
      if (quiz == null) {
        throw ApplicationException(
          'Associated quiz [${session.quizId}] not found.',
          code: 'QUIZ_NOT_FOUND',
        );
      }

      final summary =
          await _quizSessionRepository.completeSession(sessionId, quiz);
      final completedSession =
          await _quizSessionRepository.loadSession(sessionId);

      _state = ApplicationState.completed(completedSession ?? session, summary);
      return summary;
    } catch (e, st) {
      final appEx = _mapToApplicationException(e, st);
      _state = ApplicationState.error(appEx.message, appEx);
      throw appEx;
    }
  }

  /// Maps domain/infrastructure exceptions into clean ApplicationException instances.
  ApplicationException _mapToApplicationException(
      Object error, StackTrace stackTrace) {
    if (error is ApplicationException) return error;

    if (error is PdfException) {
      return ApplicationException(
        'PDF Processing Error: ${error.message}',
        code: 'PDF_ERROR',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is QuizGenerationException) {
      return ApplicationException(
        'Quiz Generation Error: ${error.message}',
        code: 'AI_QUIZ_GEN_ERROR',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is QuizSessionException) {
      return ApplicationException(
        'Quiz Session Error: ${error.message}',
        code: 'QUIZ_SESSION_ERROR',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return ApplicationException(
      'An unexpected application error occurred: ${error.toString()}',
      code: 'UNEXPECTED_ERROR',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
