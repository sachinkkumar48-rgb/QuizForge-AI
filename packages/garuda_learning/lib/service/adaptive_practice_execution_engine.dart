/// Adaptive Practice Execution Engine Service (TITAN-KO-035.0 P35).
///
/// Deterministic execution orchestrator managing runtime practice sessions,
/// sequential question presentation, answer submission validation, immediate
/// correctness evaluation, multi-mode feedback exposure, real-time progress
/// tracking, and evidence-ready P19 handoff preparation.
///
/// Invariants:
/// - Zero attempt/database persistence (owned by P19).
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Zero question fabrication or answer key tampering.
/// - Zero cognitive/predictive exam claims.
/// - Pure deterministic transitions returning new immutable state objects.
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/adaptive_practice_session_spec.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/practice_execution_error.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/question_attempt.dart';

/// Pure deterministic execution orchestrator for practice sessions.
class AdaptivePracticeExecutionEngine {
  const AdaptivePracticeExecutionEngine();

  /// Initializes a transient execution state from a P34 session specification.
  PracticeExecutionState initializeSession({
    required AdaptivePracticeSessionSpec spec,
    PracticeFeedbackPolicy feedbackPolicy = PracticeFeedbackPolicy.immediate,
    bool allowSkip = true,
  }) {
    final resultsMap = <String, PracticeQuestionResult>{};

    for (int i = 0; i < spec.orderedQuestions.length; i++) {
      final q = spec.orderedQuestions[i];
      final candidate =
          i < spec.orderedCandidates.length ? spec.orderedCandidates[i] : null;

      resultsMap[q.id] = PracticeQuestionResult.unattempted(
        index: i,
        question: q,
        candidate: candidate,
      );
    }

    return PracticeExecutionState(
      sessionId: spec.sessionId,
      examId: spec.examId,
      learnerId: spec.learnerId,
      spec: spec,
      feedbackPolicy: feedbackPolicy,
      allowSkip: allowSkip,
      status: PracticeExecutionStatus.notStarted,
      currentQuestionIndex: 0,
      questionResults: resultsMap,
      events: const [],
    );
  }

  /// Starts execution of the initialized practice session.
  PracticeExecutionResult<PracticeExecutionState> startSession({
    required PracticeExecutionState state,
    required DateTime startedAt,
  }) {
    if (state.status != PracticeExecutionStatus.notStarted) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidTransition,
        message:
            'Cannot start session from status "${state.status.name}". Must be "notStarted".',
        details: {'status': state.status.name, 'sessionId': state.sessionId},
      ));
    }

    final events = <PracticeExecutionEvent>[
      PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_start',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionStarted,
        timestamp: startedAt,
        payload: {
          'examId': state.examId,
          'totalQuestions': state.totalQuestions,
          'feedbackPolicy': state.feedbackPolicy.name,
          'allowSkip': state.allowSkip,
        },
      ),
    ];

    // Handle edge case of empty session
    if (state.totalQuestions == 0) {
      events.add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_complete',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionCompleted,
        timestamp: startedAt,
        payload: {'reason': 'empty_session', 'totalQuestions': 0},
      ));

      return PracticeExecutionResult.success(state.copyWith(
        status: PracticeExecutionStatus.completed,
        events: events,
        startedAt: startedAt,
        lastActionAt: startedAt,
        completedAt: startedAt,
      ));
    }

    // Present initial question
    final firstQ = state.spec.orderedQuestions.first;
    events.add(PracticeExecutionEvent(
      eventId: 'evt_${state.sessionId}_q0_present',
      sessionId: state.sessionId,
      type: PracticeExecutionEventType.questionPresented,
      timestamp: startedAt,
      payload: {
        'questionIndex': 0,
        'questionId': firstQ.id,
        'subject': firstQ.subject,
        'topic': firstQ.topic,
      },
    ));

    final updatedResults =
        Map<String, PracticeQuestionResult>.from(state.questionResults);
    final firstResult = updatedResults[firstQ.id];
    if (firstResult != null) {
      updatedResults[firstQ.id] = PracticeQuestionResult(
        questionId: firstResult.questionId,
        questionIndex: firstResult.questionIndex,
        isAnswered: firstResult.isAnswered,
        isSkipped: firstResult.isSkipped,
        submittedAnswer: firstResult.submittedAnswer,
        isCorrect: firstResult.isCorrect,
        feedback: firstResult.feedback,
        presentedAt: startedAt,
        answeredAt: firstResult.answeredAt,
        elapsedSeconds: firstResult.elapsedSeconds,
        candidateMetadata: firstResult.candidateMetadata,
        question: firstResult.question,
      );
    }

    return PracticeExecutionResult.success(state.copyWith(
      status: PracticeExecutionStatus.inProgress,
      questionResults: updatedResults,
      events: events,
      startedAt: startedAt,
      lastActionAt: startedAt,
    ));
  }

  /// Returns the current question presented to the learner without side effects.
  NormalizedQuestion? getCurrentQuestion(PracticeExecutionState state) {
    return state.currentQuestion;
  }

  /// Submits an answer to the current question, evaluates correctness, generates
  /// policy-compliant feedback, updates progress, and advances cursor.
  PracticeExecutionResult<PracticeExecutionState> submitAnswer({
    required PracticeExecutionState state,
    required String questionId,
    required String answer,
    required DateTime submittedAt,
  }) {
    // 1. Session Status Validation
    if (state.status == PracticeExecutionStatus.notStarted) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.sessionNotStarted,
        message: 'Session has not been started yet. Call startSession first.',
        details: {'sessionId': state.sessionId},
      ));
    }
    if (state.status == PracticeExecutionStatus.completed) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.sessionCompleted,
        message: 'Cannot submit answer; session is already completed.',
        details: {'sessionId': state.sessionId},
      ));
    }
    if (state.status == PracticeExecutionStatus.abandoned) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.sessionAbandoned,
        message: 'Cannot submit answer; session has been abandoned.',
        details: {'sessionId': state.sessionId},
      ));
    }
    if (state.status == PracticeExecutionStatus.paused) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.sessionPaused,
        message: 'Cannot submit answer while session is paused. Resume first.',
        details: {'sessionId': state.sessionId},
      ));
    }

    // 2. Question Existence & Isolation Validation
    final existingResult = state.questionResults[questionId];
    if (existingResult == null) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.questionNotFound,
        message: 'Question "$questionId" does not belong to this session.',
        details: {'questionId': questionId, 'sessionId': state.sessionId},
      ));
    }

    if (existingResult.question.examId.toLowerCase().trim() !=
        state.examId.toLowerCase().trim()) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.crossExamMismatch,
        message:
            'Question examId "${existingResult.question.examId}" does not match session examId "${state.examId}".',
        details: {
          'questionExamId': existingResult.question.examId,
          'sessionExamId': state.examId,
        },
      ));
    }

    // 3. Question Cursor Validation (Current Question Match)
    if (state.currentQuestionId != questionId) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.wrongQuestion,
        message:
            'Submitted questionId "$questionId" does not match current question index (${state.currentQuestionIndex}: "${state.currentQuestionId}").',
        details: {
          'submittedQuestionId': questionId,
          'expectedQuestionId': state.currentQuestionId,
          'currentIndex': state.currentQuestionIndex,
        },
      ));
    }

    // 4. Duplicate Answer Check
    if (existingResult.isAnswered) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.questionAlreadyAnswered,
        message:
            'Question "$questionId" has already been answered and cannot be resubmitted.',
        details: {
          'questionId': questionId,
          'previouslySubmitted': existingResult.submittedAnswer,
        },
      ));
    }

    // 5. Answer Payload Validation
    final cleanAnswer = answer.trim();
    if (cleanAnswer.isEmpty) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidAnswer,
        message: 'Submitted answer cannot be empty or blank.',
        details: {'questionId': questionId},
      ));
    }

    // 6. Correctness Evaluation against Authoritative Key
    final question = existingResult.question;
    final isCorrect = _evaluateCorrectness(question, cleanAnswer);

    // 7. Policy-Compliant Feedback Construction
    final feedback = _buildFeedback(
      question: question,
      submittedAnswer: cleanAnswer,
      isCorrect: isCorrect,
      policy: state.feedbackPolicy,
    );

    // 8. Workload Elapsed Time Calculation
    final presentedTime = existingResult.presentedAt ??
        state.lastActionAt ??
        state.startedAt ??
        submittedAt;
    final elapsedSec =
        submittedAt.difference(presentedTime).inSeconds.clamp(0, 86400);

    // 9. Update Question Result
    final updatedResult = existingResult.copyWithAnswer(
      answer: cleanAnswer,
      isCorrect: isCorrect,
      feedback: feedback,
      answeredAt: submittedAt,
      elapsedSeconds: elapsedSec,
    );

    final updatedResults =
        Map<String, PracticeQuestionResult>.from(state.questionResults);
    updatedResults[questionId] = updatedResult;

    // 10. Advance Question Index & Events
    final nextIndex = state.currentQuestionIndex + 1;
    final isSessionFinished = nextIndex >= state.totalQuestions;

    final events = List<PracticeExecutionEvent>.from(state.events)
      ..add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_q${existingResult.questionIndex}_ans',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.answerSubmitted,
        timestamp: submittedAt,
        payload: {
          'questionId': questionId,
          'questionIndex': existingResult.questionIndex,
          'submittedAnswer': cleanAnswer,
          'isCorrect': isCorrect,
          'elapsedSeconds': elapsedSec,
        },
      ))
      ..add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_q${existingResult.questionIndex}_fb',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.feedbackGenerated,
        timestamp: submittedAt,
        payload: {
          'questionId': questionId,
          'isCorrect': isCorrect,
          'isExplanationExposed': feedback.isExplanationExposed,
        },
      ));

    PracticeExecutionStatus nextStatus = state.status;
    DateTime? completedAt = state.completedAt;

    if (isSessionFinished) {
      nextStatus = PracticeExecutionStatus.completed;
      completedAt = submittedAt;
      events.add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_complete',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionCompleted,
        timestamp: submittedAt,
        payload: {
          'totalQuestions': state.totalQuestions,
          'finalStatus': nextStatus.name,
        },
      ));
    } else {
      // Present next question
      final nextQ = state.spec.orderedQuestions[nextIndex];
      events.add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_q${nextIndex}_present',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.questionPresented,
        timestamp: submittedAt,
        payload: {
          'questionIndex': nextIndex,
          'questionId': nextQ.id,
          'subject': nextQ.subject,
          'topic': nextQ.topic,
        },
      ));

      final nextResult = updatedResults[nextQ.id];
      if (nextResult != null) {
        updatedResults[nextQ.id] = PracticeQuestionResult(
          questionId: nextResult.questionId,
          questionIndex: nextResult.questionIndex,
          isAnswered: nextResult.isAnswered,
          isSkipped: nextResult.isSkipped,
          submittedAnswer: nextResult.submittedAnswer,
          isCorrect: nextResult.isCorrect,
          feedback: nextResult.feedback,
          presentedAt: submittedAt,
          answeredAt: nextResult.answeredAt,
          elapsedSeconds: nextResult.elapsedSeconds,
          candidateMetadata: nextResult.candidateMetadata,
          question: nextResult.question,
        );
      }
    }

    return PracticeExecutionResult.success(state.copyWith(
      status: nextStatus,
      currentQuestionIndex: nextIndex,
      questionResults: updatedResults,
      events: events,
      lastActionAt: submittedAt,
      completedAt: completedAt,
    ));
  }

  /// Skips the currently presented question without penalizing accuracy.
  PracticeExecutionResult<PracticeExecutionState> skipQuestion({
    required PracticeExecutionState state,
    required String questionId,
    required DateTime skippedAt,
  }) {
    if (!state.allowSkip) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.skipNotAllowed,
        message:
            'Question skipping is not permitted under the active configuration.',
        details: {'sessionId': state.sessionId},
      ));
    }

    if (state.status != PracticeExecutionStatus.inProgress) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidTransition,
        message:
            'Cannot skip question when session status is "${state.status.name}". Must be "inProgress".',
        details: {'status': state.status.name},
      ));
    }

    final existingResult = state.questionResults[questionId];
    if (existingResult == null) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.questionNotFound,
        message: 'Question "$questionId" does not belong to this session.',
        details: {'questionId': questionId},
      ));
    }

    if (state.currentQuestionId != questionId) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.wrongQuestion,
        message:
            'Skipped questionId "$questionId" does not match current question index (${state.currentQuestionIndex}: "${state.currentQuestionId}").',
        details: {
          'skippedQuestionId': questionId,
          'expectedQuestionId': state.currentQuestionId,
        },
      ));
    }

    if (existingResult.isAnswered) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.questionAlreadyAnswered,
        message:
            'Question "$questionId" has already been answered and cannot be skipped.',
        details: {'questionId': questionId},
      ));
    }

    final presentedTime = existingResult.presentedAt ??
        state.lastActionAt ??
        state.startedAt ??
        skippedAt;
    final elapsedSec =
        skippedAt.difference(presentedTime).inSeconds.clamp(0, 86400);

    final updatedResult = existingResult.copyWithSkip(
      skippedAt: skippedAt,
      elapsedSeconds: elapsedSec,
    );

    final updatedResults =
        Map<String, PracticeQuestionResult>.from(state.questionResults);
    updatedResults[questionId] = updatedResult;

    final nextIndex = state.currentQuestionIndex + 1;
    final isSessionFinished = nextIndex >= state.totalQuestions;

    final events = List<PracticeExecutionEvent>.from(state.events)
      ..add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_q${existingResult.questionIndex}_skip',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.questionSkipped,
        timestamp: skippedAt,
        payload: {
          'questionId': questionId,
          'questionIndex': existingResult.questionIndex,
          'elapsedSeconds': elapsedSec,
        },
      ));

    PracticeExecutionStatus nextStatus = state.status;
    DateTime? completedAt = state.completedAt;

    if (isSessionFinished) {
      nextStatus = PracticeExecutionStatus.completed;
      completedAt = skippedAt;
      events.add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_complete',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionCompleted,
        timestamp: skippedAt,
        payload: {
          'totalQuestions': state.totalQuestions,
          'finalStatus': nextStatus.name,
        },
      ));
    } else {
      final nextQ = state.spec.orderedQuestions[nextIndex];
      events.add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_q${nextIndex}_present',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.questionPresented,
        timestamp: skippedAt,
        payload: {
          'questionIndex': nextIndex,
          'questionId': nextQ.id,
          'subject': nextQ.subject,
          'topic': nextQ.topic,
        },
      ));

      final nextResult = updatedResults[nextQ.id];
      if (nextResult != null) {
        updatedResults[nextQ.id] = PracticeQuestionResult(
          questionId: nextResult.questionId,
          questionIndex: nextResult.questionIndex,
          isAnswered: nextResult.isAnswered,
          isSkipped: nextResult.isSkipped,
          submittedAnswer: nextResult.submittedAnswer,
          isCorrect: nextResult.isCorrect,
          feedback: nextResult.feedback,
          presentedAt: skippedAt,
          answeredAt: nextResult.answeredAt,
          elapsedSeconds: nextResult.elapsedSeconds,
          candidateMetadata: nextResult.candidateMetadata,
          question: nextResult.question,
        );
      }
    }

    return PracticeExecutionResult.success(state.copyWith(
      status: nextStatus,
      currentQuestionIndex: nextIndex,
      questionResults: updatedResults,
      events: events,
      lastActionAt: skippedAt,
      completedAt: completedAt,
    ));
  }

  /// Pauses active practice session execution.
  PracticeExecutionResult<PracticeExecutionState> pauseSession({
    required PracticeExecutionState state,
    required DateTime pausedAt,
  }) {
    if (state.status != PracticeExecutionStatus.inProgress) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidTransition,
        message:
            'Cannot pause session in status "${state.status.name}". Must be "inProgress".',
        details: {'status': state.status.name},
      ));
    }

    final events = List<PracticeExecutionEvent>.from(state.events)
      ..add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_pause',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionPaused,
        timestamp: pausedAt,
        payload: {'pausedAtIndex': state.currentQuestionIndex},
      ));

    return PracticeExecutionResult.success(state.copyWith(
      status: PracticeExecutionStatus.paused,
      events: events,
      lastActionAt: pausedAt,
    ));
  }

  /// Resumes a paused practice session.
  PracticeExecutionResult<PracticeExecutionState> resumeSession({
    required PracticeExecutionState state,
    required DateTime resumedAt,
  }) {
    if (state.status != PracticeExecutionStatus.paused) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidTransition,
        message:
            'Cannot resume session in status "${state.status.name}". Must be "paused".',
        details: {'status': state.status.name},
      ));
    }

    final events = List<PracticeExecutionEvent>.from(state.events)
      ..add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_resume',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionResumed,
        timestamp: resumedAt,
        payload: {'resumedAtIndex': state.currentQuestionIndex},
      ));

    return PracticeExecutionResult.success(state.copyWith(
      status: PracticeExecutionStatus.inProgress,
      events: events,
      lastActionAt: resumedAt,
    ));
  }

  /// Abandons the practice session before completion.
  PracticeExecutionResult<PracticeExecutionState> abandonSession({
    required PracticeExecutionState state,
    required DateTime abandonedAt,
    String? reason,
  }) {
    if (state.status.isTerminal) {
      return PracticeExecutionResult.failure(PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidTransition,
        message:
            'Cannot abandon session in terminal status "${state.status.name}".',
        details: {'status': state.status.name},
      ));
    }

    final events = List<PracticeExecutionEvent>.from(state.events)
      ..add(PracticeExecutionEvent(
        eventId: 'evt_${state.sessionId}_abandon',
        sessionId: state.sessionId,
        type: PracticeExecutionEventType.sessionAbandoned,
        timestamp: abandonedAt,
        payload: {
          'abandonedAtIndex': state.currentQuestionIndex,
          if (reason != null) 'reason': reason,
        },
      ));

    return PracticeExecutionResult.success(state.copyWith(
      status: PracticeExecutionStatus.abandoned,
      events: events,
      lastActionAt: abandonedAt,
      completedAt: abandonedAt,
    ));
  }

  /// Converts all answered question results into evidence-ready P18 [QuestionAttempt]
  /// objects for downstream persistence in P19.
  List<QuestionAttempt> generateHandoffAttempts(PracticeExecutionState state) {
    final attempts = <QuestionAttempt>[];

    for (final r in state.orderedResults) {
      if (!r.isAnswered || r.submittedAnswer == null) continue;

      final primaryObjective = r.question.objectiveIds.isNotEmpty
          ? r.question.objectiveIds.first
          : 'lo_unassigned';

      attempts.add(QuestionAttempt(
        attemptId: 'att_${state.sessionId}_${r.questionId}',
        learnerId: state.learnerId ?? 'anonymous_learner',
        questionId: r.questionId,
        objectiveId: primaryObjective,
        submittedAnswer: r.submittedAnswer!,
        attemptedAt:
            r.answeredAt ?? state.startedAt ?? DateTime.utc(2026, 9, 1),
        sessionId: state.sessionId,
      ));
    }

    return List<QuestionAttempt>.unmodifiable(attempts);
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Evaluates answer correctness against authoritative question data.
  bool _evaluateCorrectness(
      NormalizedQuestion question, String submittedAnswer) {
    final cleanSubmitted = submittedAnswer.trim().toUpperCase();

    // 1. Check officialAnswer.correctOptionKeys (e.g. ['A'] or ['A', 'B'])
    final officialKeys = question.officialAnswer.correctOptionKeys
        .map((k) => k.trim().toUpperCase())
        .toList();

    if (officialKeys.contains(cleanSubmitted)) {
      return true;
    }

    // 2. Check options marked isCorrect
    final correctFromOptions = question.options
        .where((opt) => opt.isCorrect)
        .map((opt) => opt.key.trim().toUpperCase())
        .toList();

    if (correctFromOptions.contains(cleanSubmitted)) {
      return true;
    }

    // 3. Exact text match against descriptive answer or correct option text
    if (question.officialAnswer.descriptiveAnswer != null &&
        question.officialAnswer.descriptiveAnswer!.trim().toLowerCase() ==
            submittedAnswer.trim().toLowerCase()) {
      return true;
    }

    for (final opt in question.options) {
      if (opt.isCorrect &&
          opt.text.trim().toLowerCase() ==
              submittedAnswer.trim().toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Builds policy-compliant feedback model.
  PracticeFeedback _buildFeedback({
    required NormalizedQuestion question,
    required String submittedAnswer,
    required bool isCorrect,
    required PracticeFeedbackPolicy policy,
  }) {
    final correctKeysStr = question.officialAnswer.correctOptionKeys.isNotEmpty
        ? question.officialAnswer.correctOptionKeys.join(', ')
        : question.options
            .where((o) => o.isCorrect)
            .map((o) => o.key)
            .join(', ');

    switch (policy) {
      case PracticeFeedbackPolicy.immediate:
        return PracticeFeedback(
          questionId: question.id,
          isCorrect: isCorrect,
          submittedAnswer: submittedAnswer,
          correctAnswer: correctKeysStr,
          explanation: question.explanation,
          isExplanationExposed: true,
          evaluationMethod: EvaluationMethod.multipleChoice,
          feedbackText: isCorrect
              ? 'Correct'
              : 'Incorrect. Correct answer is $correctKeysStr.',
        );

      case PracticeFeedbackPolicy.deferred:
        // Record correctness internally, withhold detailed explanation until completion
        return PracticeFeedback(
          questionId: question.id,
          isCorrect: isCorrect,
          submittedAnswer: submittedAnswer,
          correctAnswer: correctKeysStr,
          explanation: '',
          isExplanationExposed: false,
          evaluationMethod: EvaluationMethod.multipleChoice,
          feedbackText: 'Answer recorded.',
        );

      case PracticeFeedbackPolicy.examSimulation:
        // Withhold correctness and explanation completely during execution
        return PracticeFeedback(
          questionId: question.id,
          isCorrect: false, // Hidden in exposed feedback
          submittedAnswer: submittedAnswer,
          correctAnswer: '',
          explanation: '',
          isExplanationExposed: false,
          evaluationMethod: EvaluationMethod.multipleChoice,
          feedbackText: 'Answer submitted.',
        );
    }
  }
}
