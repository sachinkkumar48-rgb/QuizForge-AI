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

  ApplicationState _state = const ApplicationState.idle();

  ApplicationCoordinator({
    required PdfRepository pdfRepository,
    required QuizGenerationRepository quizGenerationRepository,
    required QuizSessionRepository quizSessionRepository,
    required QuizRepository quizRepository,
  })  : _pdfRepository = pdfRepository,
        _quizGenerationRepository = quizGenerationRepository,
        _quizSessionRepository = quizSessionRepository,
        _quizRepository = quizRepository;

  /// Returns the current immutable application state.
  ApplicationState get state => _state;

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
