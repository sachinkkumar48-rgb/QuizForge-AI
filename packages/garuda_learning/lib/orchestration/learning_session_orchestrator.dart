/// Learning Session Orchestrator Service (TITAN-KO-019.0 P19).
///
/// Central application orchestrator managing the learning-session lifecycle,
/// coordinating deterministic question selection, sequencing, P18 assessment submission,
/// and progress reporting.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show LegalQuestion, QuestionKnowledgeProductService;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/learning_session.dart';
import '../domain/entities/learning_session_state.dart';
import '../domain/entities/session_configuration.dart';
import '../domain/entities/session_progress_summary.dart';
import '../repository/attempt_repository.dart';
import '../repository/learner_repository.dart';
import '../service/assessment_service.dart';
import '../service/curriculum_service.dart';
import '../service/progress_tracker.dart';
import '../service/session_manager.dart';
import 'question_selector.dart';
import 'question_sequencer.dart';

class LearningSessionOrchestrator {
  final LearnerRepository _learnerRepository;
  final CurriculumService _curriculumService;
  final QuestionKnowledgeProductService _questionService;
  final AssessmentService _assessmentService;
  final SessionManager _sessionManager;
  final AttemptRepository _attemptRepository;
  final QuestionSelector _questionSelector;
  final QuestionSequencer _questionSequencer;

  final Map<String, LearningSession> _sessions = {};

  LearningSessionOrchestrator({
    required LearnerRepository learnerRepository,
    required CurriculumService curriculumService,
    QuestionKnowledgeProductService? questionService,
    required AssessmentService assessmentService,
    required SessionManager sessionManager,
    required AttemptRepository attemptRepository,
    required ProgressTracker progressTracker,
    QuestionSelector? questionSelector,
    QuestionSequencer? questionSequencer,
  })  : _learnerRepository = learnerRepository,
        _curriculumService = curriculumService,
        _questionService = questionService ?? QuestionKnowledgeProductService(),
        _assessmentService = assessmentService,
        _sessionManager = sessionManager,
        _attemptRepository = attemptRepository,
        _questionSelector = questionSelector ??
            QuestionSelector(
              questionService: questionService,
              curriculumService: curriculumService,
              attemptRepository: attemptRepository,
            ),
        _questionSequencer = questionSequencer ??
            QuestionSequencer(curriculumService: curriculumService);

  /// Initializes and creates a new [LearningSession] for a verified learner.
  LearningSession createSession(
    SessionConfiguration config, {
    String? sessionId,
  }) {
    // 1. Validate Learner
    if (!_learnerRepository.exists(config.learnerId)) {
      throw ArgumentError(
          'Learner "${config.learnerId}" does not exist in repository');
    }

    // 2. Validate Objectives
    for (final objId in config.objectiveIds) {
      if (_curriculumService.getObjectiveById(objId) == null) {
        throw ArgumentError(
            'Learning objective "$objId" does not exist in curriculum framework');
      }
    }

    // 3. Select Questions
    final selectedQuestions = _questionSelector.selectQuestions(
      objectiveIds: config.objectiveIds,
      learnerId: config.learnerId,
      policy: config.selectionPolicy,
      limit: config.questionLimit,
    );

    if (selectedQuestions.isEmpty) {
      throw ArgumentError(
          'No questions found matching objective(s) ${config.objectiveIds}');
    }

    // 4. Sequence Questions
    final id = sessionId ??
        'lsess_${config.learnerId}_${DateTime.now().toUtc().millisecondsSinceEpoch}';

    final sequencedQuestions = _questionSequencer.sequenceQuestions(
      questions: selectedQuestions,
      objectiveIds: config.objectiveIds,
      policy: config.sequencerPolicy,
      seed: '${config.learnerId}_$id',
    );

    final orderedQuestionIds =
        sequencedQuestions.map((q) => q.questionId).toList();

    // 5. Initialize linked P18 AssessmentSession. When a learning session ID
    // is recreated, reuse the existing linked P18 session instead of
    // attempting to start a duplicate (SessionManager rejects duplicate IDs).
    final p18SessionId = 'p18_$id';
    final p18Session = _sessionManager.getSession(p18SessionId) ??
        _sessionManager.startSession(
          learnerId: config.learnerId,
          objectiveIds: config.objectiveIds,
          questionIds: orderedQuestionIds,
          sessionId: p18SessionId,
        );

    // 6. Instantiate LearningSession
    final session = LearningSession(
      sessionId: id,
      learnerId: config.learnerId,
      configuration: config,
      orderedQuestionIds: orderedQuestionIds,
      currentQuestionIndex: 0,
      state: LearningSessionState.created,
      assessmentSessionId: p18Session.sessionId,
    );

    _sessions[id] = session;
    return session;
  }

  /// Starts an active learning session.
  LearningSession startSession(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }
    final updated = session.start();
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Returns the P15 [LegalQuestion] currently presented in the session, or null if finished.
  LegalQuestion? getCurrentQuestion(String sessionId) {
    final session = getSession(sessionId);
    if (session == null || session.isFinished) return null;
    final qId = session.currentQuestionId;
    if (qId == null) return null;
    return _resolveQuestion(qId);
  }

  /// Submits an answer for the current question in the session.
  ///
  /// Evaluates answer via P18 [AssessmentService], records attempt, updates session progress,
  /// and automatically completes session when all questions are finished.
  AttemptResult submitAnswer(
    String sessionId,
    String submittedAnswer, {
    EvaluationMethod? evaluationMethod,
  }) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }
    if (session.state != LearningSessionState.active) {
      throw StateError(
          'Cannot submit answer to a session in state ${session.state.name}');
    }
    if (session.isFinished) {
      throw StateError('Cannot submit answer to a completed session');
    }

    final questionId = session.currentQuestionId;
    if (questionId == null) {
      throw StateError('No current question presented in session');
    }

    // Determine target objective ID for question
    final objectiveId = session.configuration.objectiveIds.first;

    // Submit attempt to P18 AssessmentService
    final result = _assessmentService.submitAttempt(
      learnerId: session.learnerId,
      questionId: questionId,
      objectiveId: objectiveId,
      submittedAnswer: submittedAnswer,
      sessionId: session.assessmentSessionId,
      evaluationMethod: evaluationMethod,
    );

    // Record attempt in LearningSession state
    var updated = session.recordAttempt(result.attemptId);

    if (updated.isFinished && updated.state != LearningSessionState.completed) {
      updated = updated.complete();
      if (session.assessmentSessionId != null) {
        _sessionManager.completeSession(session.assessmentSessionId!);
      }
    }

    _sessions[sessionId] = updated;
    return result;
  }

  /// Pauses an active session.
  LearningSession pauseSession(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }
    final updated = session.pause();
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Resumes a paused session.
  LearningSession resumeSession(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }
    final updated = session.resume();
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Formally completes a session.
  LearningSession completeSession(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }
    final updated = session.complete();
    if (session.assessmentSessionId != null) {
      _sessionManager.completeSession(session.assessmentSessionId!);
    }
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Cancels a session.
  LearningSession cancelSession(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }
    final updated = session.cancel();
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Retrieves a session by ID, or null if not found.
  LearningSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// Calculates and returns a read-only [SessionProgressSummary] for a session.
  SessionProgressSummary getSessionProgress(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Learning session "$sessionId" does not exist');
    }

    var correctCount = 0;
    for (final attId in session.submittedAttemptIds) {
      final res = _attemptRepository.getResultForAttempt(attId);
      if (res != null && res.isCorrect) {
        correctCount++;
      }
    }

    final answeredCount = session.submittedAttemptIds.length;
    final currentScore = answeredCount == 0
        ? 0.0
        : (correctCount / answeredCount).clamp(0.0, 1.0);

    return SessionProgressSummary(
      sessionId: session.sessionId,
      learnerId: session.learnerId,
      totalQuestions: session.totalQuestions,
      answeredCount: answeredCount,
      correctCount: correctCount,
      currentScore: currentScore,
      state: session.state,
      isCompleted: session.isFinished,
    );
  }

  /// Retrieves all sessions for a specific learner in deterministic order.
  List<LearningSession> getSessionsForLearner(String learnerId) {
    final list = _sessions.values
        .where((s) => s.learnerId == learnerId)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List.unmodifiable(list);
  }

  /// Resolves a P15 question ID across all available products.
  LegalQuestion? _resolveQuestion(String questionId) {
    final allProducts = _questionService.buildAll();
    for (final product in allProducts) {
      for (final q in product.questions) {
        if (q.questionId == questionId) return q;
      }
    }
    return null;
  }

  /// Clears stored sessions (for testing).
  void clear() {
    _sessions.clear();
  }
}
