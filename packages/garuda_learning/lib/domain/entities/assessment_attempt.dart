/// Assessment Attempt Domain Entity (TITAN-KO-049.0 P49).
///
/// Encapsulates the runtime lifecycle of a learner taking an assessment,
/// answer capture, timing enforcement, and submission freezing.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle states of an assessment attempt.
enum AssessmentAttemptStatus {
  notStarted,
  inProgress,
  submitted,
  evaluated,
}

/// Immutable entity representing a learner's attempt at an assessment.
@immutable
class AssessmentAttempt {
  /// Unique canonical attempt identifier.
  final String attemptId;

  /// Target assessment identifier.
  final String assessmentId;

  /// Enrolled learner identifier.
  final String learnerId;

  /// Current attempt lifecycle status.
  final AssessmentAttemptStatus status;

  /// UTC start timestamp.
  final DateTime startedAt;

  /// UTC submission timestamp (null if still in progress).
  final DateTime? submittedAt;

  /// Map of questionId -> selected answer / option identifier.
  final Map<String, String> responses;

  /// Associated result identifier once evaluated.
  final String? resultId;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AssessmentAttempt({
    required this.attemptId,
    required this.assessmentId,
    required this.learnerId,
    this.status = AssessmentAttemptStatus.inProgress,
    DateTime? startedAt,
    this.submittedAt,
    Map<String, String>? responses,
    this.resultId,
    Map<String, dynamic>? metadata,
  })  : startedAt = (startedAt ?? DateTime.now()).toUtc(),
        responses = Map<String, String>.unmodifiable(responses ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (attemptId.trim().isEmpty) {
      throw ArgumentError('attemptId cannot be empty');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
  }

  /// Whether the attempt can still accept answer changes.
  bool get canModify => status == AssessmentAttemptStatus.inProgress;

  /// Whether the attempt has been finalized.
  bool get isFinalized =>
      status == AssessmentAttemptStatus.submitted ||
      status == AssessmentAttemptStatus.evaluated;

  /// Total questions answered so far.
  int get answeredCount => responses.length;

  /// Records or updates an answer for [questionId].
  AssessmentAttempt recordAnswer(String questionId, String answer) {
    if (!canModify) {
      throw StateError('Cannot modify answers on a finalized attempt');
    }
    final next = Map<String, String>.from(responses);
    next[questionId.trim()] = answer.trim();
    return copyWith(responses: next);
  }

  /// Finalizes and freezes the attempt for evaluation.
  AssessmentAttempt submit({DateTime? submittedAt}) {
    if (isFinalized) {
      return this; // Idempotent submission
    }
    return copyWith(
      status: AssessmentAttemptStatus.submitted,
      submittedAt: (submittedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Links the calculated result ID and marks the attempt as evaluated.
  AssessmentAttempt markEvaluated(String resultId) {
    return copyWith(
      status: AssessmentAttemptStatus.evaluated,
      resultId: resultId,
    );
  }

  /// Checks if time has expired according to [durationMinutes].
  bool isExpired(int? durationMinutes, DateTime asOfDate) {
    if (durationMinutes == null) return false;
    final limit = startedAt.add(Duration(minutes: durationMinutes));
    return asOfDate.toUtc().isAfter(limit);
  }

  AssessmentAttempt copyWith({
    String? attemptId,
    String? assessmentId,
    String? learnerId,
    AssessmentAttemptStatus? status,
    DateTime? startedAt,
    DateTime? submittedAt,
    Map<String, String>? responses,
    String? resultId,
    Map<String, dynamic>? metadata,
  }) {
    return AssessmentAttempt(
      attemptId: attemptId ?? this.attemptId,
      assessmentId: assessmentId ?? this.assessmentId,
      learnerId: learnerId ?? this.learnerId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      responses: responses ?? this.responses,
      resultId: resultId ?? this.resultId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'assessmentId': assessmentId,
        'learnerId': learnerId,
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
        'responses': responses,
        if (resultId != null) 'resultId': resultId,
        'metadata': metadata,
      };

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) =>
      AssessmentAttempt(
        attemptId: json['attemptId'] as String? ?? '',
        assessmentId: json['assessmentId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        status: AssessmentAttemptStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AssessmentAttemptStatus.inProgress,
        ),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String).toUtc()
            : null,
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String).toUtc()
            : null,
        responses: Map<String, String>.from(
            json['responses'] as Map? ?? const <String, String>{}),
        resultId: json['resultId'] as String?,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentAttempt &&
          attemptId == other.attemptId &&
          assessmentId == other.assessmentId &&
          learnerId == other.learnerId &&
          status == other.status &&
          startedAt == other.startedAt &&
          submittedAt == other.submittedAt &&
          resultId == other.resultId;

  @override
  int get hashCode =>
      Object.hash(attemptId, assessmentId, learnerId, status, startedAt);

  @override
  String toString() =>
      'AssessmentAttempt(id: $attemptId, assessment: $assessmentId, learner: $learnerId, answered: ${responses.length}, status: ${status.name})';
}
