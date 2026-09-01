/// Practice Execution State & Feedback Domain Entities (TITAN-KO-035.0 P35).
///
/// Encapsulates transient runtime execution state, question results,
/// real-time progress snapshots, multi-mode feedback models, completion summaries,
/// and deterministic execution events for practice session execution.
///
/// Invariants:
/// - Pure transient state; zero attempt/database persistence ownership (owned by P19).
/// - Zero cognitive/scientific prediction claims regarding future exams.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Immutable domain models and collections.
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import 'adaptive_practice_session_spec.dart';
import 'adaptive_question_candidate.dart';
import 'evaluation_method.dart';

/// Runtime execution status of an active practice session.
enum PracticeExecutionStatus {
  /// Session initialized from P34 specification, not yet started.
  notStarted,

  /// Session actively executing, presenting questions and receiving answers.
  inProgress,

  /// Session temporarily paused by learner.
  paused,

  /// Session completed (all questions processed or explicitly finished).
  completed,

  /// Session explicitly abandoned before completion.
  abandoned;

  /// Whether the session is in a terminal state.
  bool get isTerminal =>
      this == PracticeExecutionStatus.completed ||
      this == PracticeExecutionStatus.abandoned;

  /// Whether the session is active and can receive learner actions.
  bool get isActive => this == PracticeExecutionStatus.inProgress;
}

/// Feedback exposure policy during practice session execution.
enum PracticeFeedbackPolicy {
  /// Immediate feedback: correctness and explanation exposed after every answer.
  immediate,

  /// Deferred feedback: correctness recorded internally; detailed explanation
  /// withheld until session completion.
  deferred,

  /// Exam simulation: both correctness and explanations withheld until session completion.
  examSimulation;
}

/// Feedback generated for a single submitted question answer.
@immutable
class PracticeFeedback {
  /// Identifier of the question.
  final String questionId;

  /// Whether the submitted answer matches the official answer key.
  final bool isCorrect;

  /// The raw answer string submitted by the learner.
  final String submittedAnswer;

  /// The official correct answer keys/text.
  final String correctAnswer;

  /// Authoritative explanation from the question corpus.
  final String explanation;

  /// Whether the explanation is exposed to the learner under current policy.
  final bool isExplanationExposed;

  /// Method used to evaluate correctness.
  final EvaluationMethod evaluationMethod;

  /// Optional contextual feedback message.
  final String? feedbackText;

  const PracticeFeedback({
    required this.questionId,
    required this.isCorrect,
    required this.submittedAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.isExplanationExposed,
    required this.evaluationMethod,
    this.feedbackText,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'isCorrect': isCorrect,
        'submittedAnswer': submittedAnswer,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'isExplanationExposed': isExplanationExposed,
        'evaluationMethod': evaluationMethod.name,
        if (feedbackText != null) 'feedbackText': feedbackText,
      };

  factory PracticeFeedback.fromJson(Map<String, dynamic> json) =>
      PracticeFeedback(
        questionId: json['questionId'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        submittedAnswer: json['submittedAnswer'] as String? ?? '',
        correctAnswer: json['correctAnswer'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        isExplanationExposed: json['isExplanationExposed'] as bool? ?? true,
        evaluationMethod: EvaluationMethod.values.firstWhere(
          (m) => m.name == json['evaluationMethod'],
          orElse: () => EvaluationMethod.multipleChoice,
        ),
        feedbackText: json['feedbackText'] as String?,
      );

  @override
  String toString() =>
      'PracticeFeedback($questionId: correct=$isCorrect, exposed=$isExplanationExposed)';
}

/// Execution result for a single question within the practice session.
@immutable
class PracticeQuestionResult {
  /// Canonical question ID.
  final String questionId;

  /// 0-based sequence index within the session.
  final int questionIndex;

  /// Whether the question was submitted with an answer.
  final bool isAnswered;

  /// Whether the question was explicitly skipped.
  final bool isSkipped;

  /// The submitted answer string, or null if skipped/unanswered.
  final String? submittedAnswer;

  /// Whether the submitted answer was correct (false if skipped/unanswered).
  final bool isCorrect;

  /// Generated question-level feedback, or null if unanswered/skipped.
  final PracticeFeedback? feedback;

  /// Timestamp when the question was first presented to the learner.
  final DateTime? presentedAt;

  /// Timestamp when the answer or skip action was submitted.
  final DateTime? answeredAt;

  /// Time spent on this question in seconds.
  final int elapsedSeconds;

  /// Associated question candidate metadata from P33/P34.
  final AdaptiveQuestionCandidate? candidateMetadata;

  /// Full normalized question domain entity.
  final NormalizedQuestion question;

  const PracticeQuestionResult({
    required this.questionId,
    required this.questionIndex,
    required this.isAnswered,
    required this.isSkipped,
    this.submittedAnswer,
    required this.isCorrect,
    this.feedback,
    this.presentedAt,
    this.answeredAt,
    this.elapsedSeconds = 0,
    this.candidateMetadata,
    required this.question,
  });

  /// Creates an unattempted placeholder result for an upcoming question.
  factory PracticeQuestionResult.unattempted({
    required int index,
    required NormalizedQuestion question,
    AdaptiveQuestionCandidate? candidate,
    DateTime? presentedAt,
  }) {
    return PracticeQuestionResult(
      questionId: question.id,
      questionIndex: index,
      isAnswered: false,
      isSkipped: false,
      isCorrect: false,
      presentedAt: presentedAt,
      candidateMetadata: candidate,
      question: question,
    );
  }

  /// Copies this result with updated submission data.
  PracticeQuestionResult copyWithAnswer({
    required String answer,
    required bool isCorrect,
    required PracticeFeedback feedback,
    required DateTime answeredAt,
    required int elapsedSeconds,
  }) {
    return PracticeQuestionResult(
      questionId: questionId,
      questionIndex: questionIndex,
      isAnswered: true,
      isSkipped: false,
      submittedAnswer: answer,
      isCorrect: isCorrect,
      feedback: feedback,
      presentedAt: presentedAt,
      answeredAt: answeredAt,
      elapsedSeconds: elapsedSeconds,
      candidateMetadata: candidateMetadata,
      question: question,
    );
  }

  /// Copies this result marked as skipped.
  PracticeQuestionResult copyWithSkip({
    required DateTime skippedAt,
    required int elapsedSeconds,
  }) {
    return PracticeQuestionResult(
      questionId: questionId,
      questionIndex: questionIndex,
      isAnswered: false,
      isSkipped: true,
      submittedAnswer: null,
      isCorrect: false,
      feedback: null,
      presentedAt: presentedAt,
      answeredAt: skippedAt,
      elapsedSeconds: elapsedSeconds,
      candidateMetadata: candidateMetadata,
      question: question,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionIndex': questionIndex,
        'isAnswered': isAnswered,
        'isSkipped': isSkipped,
        if (submittedAnswer != null) 'submittedAnswer': submittedAnswer,
        'isCorrect': isCorrect,
        if (feedback != null) 'feedback': feedback!.toJson(),
        if (presentedAt != null) 'presentedAt': presentedAt!.toIso8601String(),
        if (answeredAt != null) 'answeredAt': answeredAt!.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        if (candidateMetadata != null)
          'candidateMetadata': candidateMetadata!.toJson(),
        'question': question.toJson(),
      };

  factory PracticeQuestionResult.fromJson(Map<String, dynamic> json) =>
      PracticeQuestionResult(
        questionId: json['questionId'] as String? ?? '',
        questionIndex: json['questionIndex'] as int? ?? 0,
        isAnswered: json['isAnswered'] as bool? ?? false,
        isSkipped: json['isSkipped'] as bool? ?? false,
        submittedAnswer: json['submittedAnswer'] as String?,
        isCorrect: json['isCorrect'] as bool? ?? false,
        feedback: json['feedback'] != null
            ? PracticeFeedback.fromJson(
                json['feedback'] as Map<String, dynamic>)
            : null,
        presentedAt: json['presentedAt'] != null
            ? DateTime.parse(json['presentedAt'] as String).toUtc()
            : null,
        answeredAt: json['answeredAt'] != null
            ? DateTime.parse(json['answeredAt'] as String).toUtc()
            : null,
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        candidateMetadata: json['candidateMetadata'] != null
            ? AdaptiveQuestionCandidate.fromJson(
                json['candidateMetadata'] as Map<String, dynamic>)
            : null,
        question: NormalizedQuestion.fromJson(
            json['question'] as Map<String, dynamic>),
      );

  @override
  String toString() =>
      'PracticeQuestionResult($questionId: answered=$isAnswered, skipped=$isSkipped, correct=$isCorrect, elapsed=${elapsedSeconds}s)';
}

/// Live real-time snapshot of practice session progress metrics.
@immutable
class PracticeProgressSnapshot {
  /// Total scheduled questions in the session.
  final int totalQuestions;

  /// Current 0-based question cursor index.
  final int currentQuestionIndex;

  /// Human-readable 1-based question number (bounded in [1, totalQuestions]).
  final int currentQuestionNumber;

  /// Total count of questions answered so far.
  final int answeredCount;

  /// Total count of correct answers.
  final int correctCount;

  /// Total count of incorrect answers.
  final int incorrectCount;

  /// Total count of skipped questions.
  final int skippedCount;

  /// Count of remaining unprocessed questions.
  final int remainingCount;

  /// Ratio of completed/processed questions relative to total in [0.0, 1.0].
  final double completionRatio;

  /// Accuracy ratio among answered questions in [0.0, 1.0] (0.0 if answered == 0).
  final double accuracyAmongAnswered;

  /// Cumulative elapsed duration in seconds.
  final int totalElapsedSeconds;

  PracticeProgressSnapshot({
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.currentQuestionNumber,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.remainingCount,
    required this.completionRatio,
    required this.accuracyAmongAnswered,
    required this.totalElapsedSeconds,
  }) {
    if (completionRatio < 0.0 || completionRatio > 1.0) {
      throw ArgumentError('completionRatio must be in [0.0, 1.0]');
    }
    if (accuracyAmongAnswered < 0.0 || accuracyAmongAnswered > 1.0) {
      throw ArgumentError('accuracyAmongAnswered must be in [0.0, 1.0]');
    }
  }

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'currentQuestionIndex': currentQuestionIndex,
        'currentQuestionNumber': currentQuestionNumber,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'skippedCount': skippedCount,
        'remainingCount': remainingCount,
        'completionRatio': completionRatio,
        'accuracyAmongAnswered': accuracyAmongAnswered,
        'totalElapsedSeconds': totalElapsedSeconds,
      };

  factory PracticeProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      PracticeProgressSnapshot(
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
        currentQuestionNumber: json['currentQuestionNumber'] as int? ?? 1,
        answeredCount: json['answeredCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        remainingCount: json['remainingCount'] as int? ?? 0,
        completionRatio: (json['completionRatio'] as num?)?.toDouble() ?? 0.0,
        accuracyAmongAnswered:
            (json['accuracyAmongAnswered'] as num?)?.toDouble() ?? 0.0,
        totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
      );

  @override
  String toString() =>
      'PracticeProgressSnapshot(Q$currentQuestionNumber/$totalQuestions: ans=$answeredCount, corr=$correctCount, skip=$skippedCount, acc=${(accuracyAmongAnswered * 100).toStringAsFixed(1)}%)';
}

/// Performance aggregation per learning objective.
@immutable
class PracticeObjectiveSummary {
  final String objectiveId;
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final double accuracy;

  const PracticeObjectiveSummary({
    required this.objectiveId,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'totalQuestions': totalQuestions,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'accuracy': accuracy,
      };

  factory PracticeObjectiveSummary.fromJson(Map<String, dynamic> json) =>
      PracticeObjectiveSummary(
        objectiveId: json['objectiveId'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        answeredCount: json['answeredCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Performance aggregation per syllabus topic.
@immutable
class PracticeTopicSummary {
  final String topic;
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final double accuracy;

  const PracticeTopicSummary({
    required this.topic,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'totalQuestions': totalQuestions,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'accuracy': accuracy,
      };

  factory PracticeTopicSummary.fromJson(Map<String, dynamic> json) =>
      PracticeTopicSummary(
        topic: json['topic'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        answeredCount: json['answeredCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Comprehensive summary of a finalized practice session execution.
@immutable
class PracticeCompletionSummary {
  /// Session identifier.
  final String sessionId;

  /// Examination identifier.
  final String examId;

  /// Optional learner identifier.
  final String? learnerId;

  /// Final session status.
  final PracticeExecutionStatus status;

  /// Total questions scheduled.
  final int totalQuestions;

  /// Total questions answered.
  final int answeredCount;

  /// Total correct answers.
  final int correctCount;

  /// Total incorrect answers.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Overall session score ratio relative to total questions in [0.0, 1.0].
  final double score;

  /// Accuracy ratio among answered questions in [0.0, 1.0].
  final double accuracy;

  /// Total duration in seconds.
  final int totalDurationSeconds;

  /// Average seconds spent per answered question.
  final double averageSecondsPerQuestion;

  /// Timestamp when the session was started.
  final DateTime startedAt;

  /// Timestamp when the session was completed or terminated.
  final DateTime completedAt;

  /// Performance breakdown per learning objective ID.
  final Map<String, PracticeObjectiveSummary> objectivePerformance;

  /// Performance breakdown per syllabus topic.
  final Map<String, PracticeTopicSummary> topicPerformance;

  /// Ordered list of question execution results.
  final List<PracticeQuestionResult> results;

  PracticeCompletionSummary({
    required this.sessionId,
    required this.examId,
    this.learnerId,
    required this.status,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.score,
    required this.accuracy,
    required this.totalDurationSeconds,
    required this.averageSecondsPerQuestion,
    required this.startedAt,
    required this.completedAt,
    required Map<String, PracticeObjectiveSummary> objectivePerformance,
    required Map<String, PracticeTopicSummary> topicPerformance,
    required List<PracticeQuestionResult> results,
  })  : objectivePerformance =
            Map<String, PracticeObjectiveSummary>.unmodifiable(
                objectivePerformance),
        topicPerformance =
            Map<String, PracticeTopicSummary>.unmodifiable(topicPerformance),
        results = List<PracticeQuestionResult>.unmodifiable(results);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'examId': examId,
        if (learnerId != null) 'learnerId': learnerId,
        'status': status.name,
        'totalQuestions': totalQuestions,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'skippedCount': skippedCount,
        'score': score,
        'accuracy': accuracy,
        'totalDurationSeconds': totalDurationSeconds,
        'averageSecondsPerQuestion': averageSecondsPerQuestion,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'objectivePerformance':
            objectivePerformance.map((k, v) => MapEntry(k, v.toJson())),
        'topicPerformance':
            topicPerformance.map((k, v) => MapEntry(k, v.toJson())),
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory PracticeCompletionSummary.fromJson(Map<String, dynamic> json) =>
      PracticeCompletionSummary(
        sessionId: json['sessionId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        learnerId: json['learnerId'] as String?,
        status: PracticeExecutionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PracticeExecutionStatus.completed,
        ),
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        answeredCount: json['answeredCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
        averageSecondsPerQuestion:
            (json['averageSecondsPerQuestion'] as num?)?.toDouble() ?? 0.0,
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        completedAt: DateTime.parse(json['completedAt'] as String).toUtc(),
        objectivePerformance: (json['objectivePerformance']
                    as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(k,
                PracticeObjectiveSummary.fromJson(v as Map<String, dynamic>))),
        topicPerformance: (json['topicPerformance'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(
                k, PracticeTopicSummary.fromJson(v as Map<String, dynamic>))),
        results: (json['results'] as List<dynamic>? ?? const [])
            .map((r) =>
                PracticeQuestionResult.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() =>
      'PracticeCompletionSummary($sessionId [$examId]: $correctCount/$totalQuestions correct, acc=${(accuracy * 100).toStringAsFixed(1)}%, duration=${totalDurationSeconds}s)';
}

/// Categorical type of execution events.
enum PracticeExecutionEventType {
  sessionStarted,
  questionPresented,
  answerSubmitted,
  questionSkipped,
  feedbackGenerated,
  sessionPaused,
  sessionResumed,
  sessionCompleted,
  sessionAbandoned,
}

/// Deterministic audit event emitted during practice session execution.
@immutable
class PracticeExecutionEvent {
  /// Stable deterministic event identifier.
  final String eventId;

  /// Target session identifier.
  final String sessionId;

  /// Categorical event type.
  final PracticeExecutionEventType type;

  /// Caller-supplied timestamp when the event occurred.
  final DateTime timestamp;

  /// Structured event payload attributes.
  final Map<String, dynamic> payload;

  PracticeExecutionEvent({
    required this.eventId,
    required this.sessionId,
    required this.type,
    required this.timestamp,
    Map<String, dynamic>? payload,
  }) : payload = Map<String, dynamic>.unmodifiable(payload ?? const {});

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'sessionId': sessionId,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
      };

  factory PracticeExecutionEvent.fromJson(Map<String, dynamic> json) =>
      PracticeExecutionEvent(
        eventId: json['eventId'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        type: PracticeExecutionEventType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PracticeExecutionEventType.sessionStarted,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      );

  @override
  String toString() =>
      'PracticeExecutionEvent($eventId [${type.name}] at ${timestamp.toIso8601String()})';
}

/// Immutable transient practice execution state.
@immutable
class PracticeExecutionState {
  /// Session identifier matching the P34 specification.
  final String sessionId;

  /// Examination identifier.
  final String examId;

  /// Target learner identifier, if present.
  final String? learnerId;

  /// The underlying P34 practice session specification.
  final AdaptivePracticeSessionSpec spec;

  /// Active feedback exposure policy.
  final PracticeFeedbackPolicy feedbackPolicy;

  /// Whether question skipping is permitted.
  final bool allowSkip;

  /// Current lifecycle execution status.
  final PracticeExecutionStatus status;

  /// 0-based index of the currently active question.
  final int currentQuestionIndex;

  /// Indexed map of question execution results by question ID.
  final Map<String, PracticeQuestionResult> questionResults;

  /// Deterministic sequence of recorded execution events.
  final List<PracticeExecutionEvent> events;

  /// Timestamp when execution was started.
  final DateTime? startedAt;

  /// Timestamp of the most recent learner or system action.
  final DateTime? lastActionAt;

  /// Timestamp when execution reached a terminal state.
  final DateTime? completedAt;

  PracticeExecutionState({
    required this.sessionId,
    required this.examId,
    this.learnerId,
    required this.spec,
    this.feedbackPolicy = PracticeFeedbackPolicy.immediate,
    this.allowSkip = true,
    this.status = PracticeExecutionStatus.notStarted,
    this.currentQuestionIndex = 0,
    required Map<String, PracticeQuestionResult> questionResults,
    List<PracticeExecutionEvent>? events,
    this.startedAt,
    this.lastActionAt,
    this.completedAt,
  })  : questionResults =
            Map<String, PracticeQuestionResult>.unmodifiable(questionResults),
        events = List<PracticeExecutionEvent>.unmodifiable(events ?? const []) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError(
          'sessionId cannot be empty for PracticeExecutionState');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty for PracticeExecutionState');
    }
    if (currentQuestionIndex < 0) {
      throw ArgumentError(
          'currentQuestionIndex cannot be negative ($currentQuestionIndex)');
    }
  }

  /// Total number of scheduled questions.
  int get totalQuestions => spec.totalQuestions;

  /// Whether all questions have been processed or the session is finished.
  bool get isFinished =>
      currentQuestionIndex >= totalQuestions || status.isTerminal;

  /// Currently presented normalized question, or null if finished.
  NormalizedQuestion? get currentQuestion {
    if (currentQuestionIndex >= 0 &&
        currentQuestionIndex < spec.orderedQuestions.length) {
      return spec.orderedQuestions[currentQuestionIndex];
    }
    return null;
  }

  /// Currently presented question ID, or null if finished.
  String? get currentQuestionId => currentQuestion?.id;

  /// Ordered list of question execution results matching the P34 sequence.
  List<PracticeQuestionResult> get orderedResults {
    return spec.orderedQuestionIds
        .map((id) => questionResults[id])
        .whereType<PracticeQuestionResult>()
        .toList();
  }

  /// Calculates the live progress snapshot at $O(1)$ efficiency.
  PracticeProgressSnapshot get progress {
    int answered = 0;
    int correct = 0;
    int incorrect = 0;
    int skipped = 0;
    int totalElapsed = 0;

    for (final r in questionResults.values) {
      totalElapsed += r.elapsedSeconds;
      if (r.isAnswered) {
        answered++;
        if (r.isCorrect) {
          correct++;
        } else {
          incorrect++;
        }
      } else if (r.isSkipped) {
        skipped++;
      }
    }

    final total = totalQuestions;
    final processed = answered + skipped;
    final remaining = (total - processed).clamp(0, total);
    final compRatio = total > 0 ? (processed / total).clamp(0.0, 1.0) : 0.0;
    final acc = answered > 0 ? (correct / answered).clamp(0.0, 1.0) : 0.0;
    final qNum = total > 0 ? (currentQuestionIndex + 1).clamp(1, total) : 1;

    return PracticeProgressSnapshot(
      totalQuestions: total,
      currentQuestionIndex: currentQuestionIndex,
      currentQuestionNumber: qNum,
      answeredCount: answered,
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: skipped,
      remainingCount: remaining,
      completionRatio: compRatio,
      accuracyAmongAnswered: acc,
      totalElapsedSeconds: totalElapsed,
    );
  }

  /// Compiles the final completion summary.
  PracticeCompletionSummary? get completionSummary {
    if (startedAt == null) return null;

    final p = progress;
    final finalCompletedAt = completedAt ?? lastActionAt ?? startedAt!;
    final totalDuration = p.totalElapsedSeconds > 0
        ? p.totalElapsedSeconds
        : finalCompletedAt.difference(startedAt!).inSeconds.clamp(0, 86400);

    final avgSec = p.answeredCount > 0 ? totalDuration / p.answeredCount : 0.0;

    final scoreRatio = totalQuestions > 0
        ? (p.correctCount / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    // Objective performance breakdown
    final objMap = <String, Map<String, int>>{};
    for (final r in questionResults.values) {
      for (final objId in r.question.objectiveIds) {
        final current = objMap.putIfAbsent(
            objId, () => {'total': 0, 'answered': 0, 'correct': 0});
        current['total'] = current['total']! + 1;
        if (r.isAnswered) {
          current['answered'] = current['answered']! + 1;
          if (r.isCorrect) {
            current['correct'] = current['correct']! + 1;
          }
        }
      }
    }

    final objSummaries = <String, PracticeObjectiveSummary>{};
    objMap.forEach((objId, stats) {
      final ans = stats['answered']!;
      final corr = stats['correct']!;
      final acc = ans > 0 ? corr / ans : 0.0;
      objSummaries[objId] = PracticeObjectiveSummary(
        objectiveId: objId,
        totalQuestions: stats['total']!,
        answeredCount: ans,
        correctCount: corr,
        accuracy: acc,
      );
    });

    // Topic performance breakdown
    final topicMap = <String, Map<String, int>>{};
    for (final r in questionResults.values) {
      final t = r.question.topic;
      final current = topicMap.putIfAbsent(
          t, () => {'total': 0, 'answered': 0, 'correct': 0});
      current['total'] = current['total']! + 1;
      if (r.isAnswered) {
        current['answered'] = current['answered']! + 1;
        if (r.isCorrect) {
          current['correct'] = current['correct']! + 1;
        }
      }
    }

    final topicSummaries = <String, PracticeTopicSummary>{};
    topicMap.forEach((topic, stats) {
      final ans = stats['answered']!;
      final corr = stats['correct']!;
      final acc = ans > 0 ? corr / ans : 0.0;
      topicSummaries[topic] = PracticeTopicSummary(
        topic: topic,
        totalQuestions: stats['total']!,
        answeredCount: ans,
        correctCount: corr,
        accuracy: acc,
      );
    });

    return PracticeCompletionSummary(
      sessionId: sessionId,
      examId: examId,
      learnerId: learnerId,
      status: status,
      totalQuestions: totalQuestions,
      answeredCount: p.answeredCount,
      correctCount: p.correctCount,
      incorrectCount: p.incorrectCount,
      skippedCount: p.skippedCount,
      score: scoreRatio,
      accuracy: p.accuracyAmongAnswered,
      totalDurationSeconds: totalDuration,
      averageSecondsPerQuestion: avgSec,
      startedAt: startedAt!,
      completedAt: finalCompletedAt,
      objectivePerformance: objSummaries,
      topicPerformance: topicSummaries,
      results: orderedResults,
    );
  }

  /// Copies this state with updated attributes.
  PracticeExecutionState copyWith({
    PracticeExecutionStatus? status,
    int? currentQuestionIndex,
    Map<String, PracticeQuestionResult>? questionResults,
    List<PracticeExecutionEvent>? events,
    DateTime? startedAt,
    DateTime? lastActionAt,
    DateTime? completedAt,
  }) {
    return PracticeExecutionState(
      sessionId: sessionId,
      examId: examId,
      learnerId: learnerId,
      spec: spec,
      feedbackPolicy: feedbackPolicy,
      allowSkip: allowSkip,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questionResults: questionResults ?? this.questionResults,
      events: events ?? this.events,
      startedAt: startedAt ?? this.startedAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'examId': examId,
        if (learnerId != null) 'learnerId': learnerId,
        'spec': spec.toJson(),
        'feedbackPolicy': feedbackPolicy.name,
        'allowSkip': allowSkip,
        'status': status.name,
        'currentQuestionIndex': currentQuestionIndex,
        'questionResults':
            questionResults.map((k, v) => MapEntry(k, v.toJson())),
        'events': events.map((e) => e.toJson()).toList(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (lastActionAt != null)
          'lastActionAt': lastActionAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory PracticeExecutionState.fromJson(Map<String, dynamic> json) =>
      PracticeExecutionState(
        sessionId: json['sessionId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        learnerId: json['learnerId'] as String?,
        spec: AdaptivePracticeSessionSpec.fromJson(
            json['spec'] as Map<String, dynamic>),
        feedbackPolicy: PracticeFeedbackPolicy.values.firstWhere(
          (p) => p.name == json['feedbackPolicy'],
          orElse: () => PracticeFeedbackPolicy.immediate,
        ),
        allowSkip: json['allowSkip'] as bool? ?? true,
        status: PracticeExecutionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PracticeExecutionStatus.notStarted,
        ),
        currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
        questionResults: (json['questionResults'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(
                k, PracticeQuestionResult.fromJson(v as Map<String, dynamic>))),
        events: (json['events'] as List<dynamic>? ?? const [])
            .map((e) =>
                PracticeExecutionEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String).toUtc()
            : null,
        lastActionAt: json['lastActionAt'] != null
            ? DateTime.parse(json['lastActionAt'] as String).toUtc()
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'PracticeExecutionState($sessionId [$examId]: status=${status.name}, index=$currentQuestionIndex/$totalQuestions)';
}
