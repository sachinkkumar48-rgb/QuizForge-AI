/// Adaptive Learning Session Domain Entity (TITAN-KO-040.0 P40).
///
/// Encapsulates the immutable, recoverable state of an active, paused, or
/// completed adaptive learning session, tracking coordinates, question progression,
/// dual revisions, and completion metadata without duplicating authoritative learner state.
library;

import 'package:meta/meta.dart';

import 'adaptive_practice_session_config.dart';
import 'session_checkpoint_exceptions.dart';
import 'session_status.dart';

/// Immutable domain aggregate representing an adaptive learning session.
@immutable
class AdaptiveLearningSession {
  /// Unique session identifier.
  final String sessionId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier (normalized lowercase).
  final String examId;

  /// Timestamp when the session was initialized/started.
  final DateTime startedAt;

  /// Timestamp of the most recent learner or system activity.
  final DateTime lastActivityAt;

  /// Discrete lifecycle execution status.
  final SessionStatus status;

  /// Practice configuration driving this session.
  final AdaptivePracticeSessionConfig configuration;

  /// 0-based question sequence index representing the current cursor.
  final int currentQuestionPosition;

  /// Total number of questions planned for this session.
  final int totalQuestionsPlanned;

  /// Deterministically ordered sequence of question IDs completed in this session.
  final List<String> completedQuestions;

  /// Current revision of the associated AuthoritativeLearnerState (>= 1).
  final int currentLearningStateRevision;

  /// Revision of the most recently persisted session checkpoint (>= 1).
  final int checkpointRevision;

  /// Extensible completion, evaluation, and diagnostic metadata.
  final Map<String, dynamic> completionMetadata;

  AdaptiveLearningSession({
    required String sessionId,
    required String learnerId,
    required String examId,
    required DateTime startedAt,
    required DateTime lastActivityAt,
    this.status = SessionStatus.created,
    required this.configuration,
    this.currentQuestionPosition = 0,
    required this.totalQuestionsPlanned,
    List<String>? completedQuestions,
    this.currentLearningStateRevision = 1,
    this.checkpointRevision = 1,
    Map<String, dynamic>? completionMetadata,
  })  : sessionId = sessionId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        startedAt = startedAt.toUtc(),
        lastActivityAt = lastActivityAt.toUtc(),
        completedQuestions = List<String>.unmodifiable(
          List<String>.from(completedQuestions ?? const <String>[]),
        ),
        completionMetadata = Map<String, dynamic>.unmodifiable(
          completionMetadata ?? const {},
        ) {
    if (this.sessionId.isEmpty) {
      throw ArgumentError(
          'sessionId cannot be empty for AdaptiveLearningSession');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for AdaptiveLearningSession');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty for AdaptiveLearningSession');
    }
    if (currentQuestionPosition < 0) {
      throw ArgumentError(
        'currentQuestionPosition cannot be negative (got $currentQuestionPosition)',
      );
    }
    if (totalQuestionsPlanned < 0) {
      throw ArgumentError(
        'totalQuestionsPlanned cannot be negative (got $totalQuestionsPlanned)',
      );
    }
    if (currentLearningStateRevision < 1) {
      throw ArgumentError(
        'currentLearningStateRevision must be >= 1 (got $currentLearningStateRevision)',
      );
    }
    if (checkpointRevision < 1) {
      throw ArgumentError(
        'checkpointRevision must be >= 1 (got $checkpointRevision)',
      );
    }
  }

  /// Whether the session reached a terminal completion state.
  bool get isCompleted => status == SessionStatus.completed;

  /// Whether the session is active and can receive attempts.
  bool get canAcceptInput => status.canAcceptInput;

  /// Whether the session is in any terminal state (completed, abandoned, failed).
  bool get isTerminal => status.isTerminal;

  /// Number of questions completed so far.
  int get completedQuestionCount => completedQuestions.length;

  /// Transitions this session to a [target] status enforcing domain transition rules.
  AdaptiveLearningSession transitionTo(
    SessionStatus target, {
    DateTime? timestamp,
    Map<String, dynamic>? additionalMetadata,
  }) {
    if (!status.canTransitionTo(target)) {
      throw InvalidSessionTransitionException(
        message:
            'Invalid session transition from "${status.name}" to "${target.name}" for session "$sessionId"',
        from: status.name,
        to: target.name,
        details: {'sessionId': sessionId},
      );
    }

    final effectiveTs = (timestamp ?? lastActivityAt).toUtc();
    final updatedMetadata = Map<String, dynamic>.from(completionMetadata);
    if (additionalMetadata != null) {
      updatedMetadata.addAll(additionalMetadata);
    }

    return copyWith(
      status: target,
      lastActivityAt: effectiveTs,
      completionMetadata: updatedMetadata,
    );
  }

  /// Advances cursor to the next question after answering [questionId].
  AdaptiveLearningSession advanceQuestion({
    required String questionId,
    DateTime? timestamp,
  }) {
    final effectiveTs = (timestamp ?? lastActivityAt).toUtc();
    final updatedList = List<String>.from(completedQuestions);
    if (!updatedList.contains(questionId)) {
      updatedList.add(questionId);
    }

    return copyWith(
      currentQuestionPosition: currentQuestionPosition + 1,
      completedQuestions: updatedList,
      lastActivityAt: effectiveTs,
    );
  }

  /// Creates a copy of this session with modified fields.
  AdaptiveLearningSession copyWith({
    SessionStatus? status,
    AdaptivePracticeSessionConfig? configuration,
    int? currentQuestionPosition,
    int? totalQuestionsPlanned,
    List<String>? completedQuestions,
    int? currentLearningStateRevision,
    int? checkpointRevision,
    DateTime? lastActivityAt,
    Map<String, dynamic>? completionMetadata,
  }) {
    return AdaptiveLearningSession(
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      startedAt: startedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      status: status ?? this.status,
      configuration: configuration ?? this.configuration,
      currentQuestionPosition:
          currentQuestionPosition ?? this.currentQuestionPosition,
      totalQuestionsPlanned:
          totalQuestionsPlanned ?? this.totalQuestionsPlanned,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      currentLearningStateRevision:
          currentLearningStateRevision ?? this.currentLearningStateRevision,
      checkpointRevision: checkpointRevision ?? this.checkpointRevision,
      completionMetadata: completionMetadata ?? this.completionMetadata,
    );
  }

  /// Serializes to a standard JSON map.
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'learnerId': learnerId,
        'examId': examId,
        'startedAt': startedAt.toIso8601String(),
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'status': status.name,
        'configuration': configuration.toJson(),
        'currentQuestionPosition': currentQuestionPosition,
        'totalQuestionsPlanned': totalQuestionsPlanned,
        'completedQuestions': completedQuestions,
        'currentLearningStateRevision': currentLearningStateRevision,
        'checkpointRevision': checkpointRevision,
        'completionMetadata': completionMetadata,
      };

  /// Deserializes from a standard JSON map.
  factory AdaptiveLearningSession.fromJson(Map<String, dynamic> json) {
    return AdaptiveLearningSession(
      sessionId: json['sessionId'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String).toUtc(),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SessionStatus.created,
      ),
      configuration: AdaptivePracticeSessionConfig.fromJson(
        json['configuration'] as Map<String, dynamic>? ?? const {},
      ),
      currentQuestionPosition: json['currentQuestionPosition'] as int? ?? 0,
      totalQuestionsPlanned: json['totalQuestionsPlanned'] as int? ?? 0,
      completedQuestions:
          (json['completedQuestions'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      currentLearningStateRevision:
          json['currentLearningStateRevision'] as int? ?? 1,
      checkpointRevision: json['checkpointRevision'] as int? ?? 1,
      completionMetadata:
          json['completionMetadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveLearningSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          currentQuestionPosition == other.currentQuestionPosition &&
          status == other.status &&
          currentLearningStateRevision == other.currentLearningStateRevision &&
          checkpointRevision == other.checkpointRevision;

  @override
  int get hashCode => Object.hash(
        sessionId,
        learnerId,
        examId,
        currentQuestionPosition,
        status,
        currentLearningStateRevision,
        checkpointRevision,
      );

  @override
  String toString() =>
      'AdaptiveLearningSession($sessionId [$learnerId:$examId] status: ${status.name}, pos: $currentQuestionPosition/$totalQuestionsPlanned, authRev: $currentLearningStateRevision, chkRev: $checkpointRevision)';
}
