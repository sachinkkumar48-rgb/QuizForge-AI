/// Learning Activity Execution Request Domain Entity (TITAN-KO-042.0 P42).
///
/// Encapsulates the execution input dispatched to [AdaptiveLearningPlanExecutor]
/// containing the continuation plan, authoritative state snapshot, question corpus,
/// and optional existing session/checkpoint coordinates.
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import 'adaptive_practice_session_spec.dart';
import 'authoritative_learner_state.dart';
import 'learning_continuation_plan.dart';
import 'practice_execution_state.dart';
import 'session_checkpoint.dart';

/// Request payload driving deterministic execution of a [LearningContinuationPlan].
@immutable
class LearningActivityExecutionRequest {
  /// Unique identifier of this execution request.
  final String requestId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Continuation plan formulated by P41 to be executed.
  final LearningContinuationPlan plan;

  /// Authoritative learner state snapshot at the time of execution.
  final AuthoritativeLearnerState currentState;

  /// Available normalized question corpus for new session question selection.
  final List<NormalizedQuestion> corpus;

  /// Optional existing session specification when resuming an active session.
  final AdaptivePracticeSessionSpec? existingSessionSpec;

  /// Optional active session checkpoint when resuming or evaluating active conflicts.
  final SessionCheckpoint? activeCheckpoint;

  /// Feedback policy applied when a practice session is started.
  final PracticeFeedbackPolicy feedbackPolicy;

  /// Whether question skipping is permitted in the started practice session.
  final bool allowSkip;

  /// UTC timestamp when this execution request was created.
  final DateTime requestedAt;

  /// Extensible caller-supplied metadata.
  final Map<String, dynamic> metadata;

  LearningActivityExecutionRequest({
    required String requestId,
    required String learnerId,
    required String examId,
    required this.plan,
    required this.currentState,
    List<NormalizedQuestion>? corpus,
    this.existingSessionSpec,
    this.activeCheckpoint,
    this.feedbackPolicy = PracticeFeedbackPolicy.immediate,
    this.allowSkip = true,
    required DateTime requestedAt,
    Map<String, dynamic>? metadata,
  })  : requestId = requestId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        corpus = List<NormalizedQuestion>.unmodifiable(corpus ?? const []),
        requestedAt = requestedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (this.requestId.isEmpty) {
      throw ArgumentError(
          'requestId cannot be empty for LearningActivityExecutionRequest');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for LearningActivityExecutionRequest');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for LearningActivityExecutionRequest');
    }
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'learnerId': learnerId,
        'examId': examId,
        'plan': plan.toJson(),
        'currentState': currentState.toJson(),
        'corpus': corpus.map((q) => q.toJson()).toList(),
        if (existingSessionSpec != null)
          'existingSessionSpec': existingSessionSpec!.toJson(),
        if (activeCheckpoint != null)
          'activeCheckpoint': activeCheckpoint!.toJson(),
        'feedbackPolicy': feedbackPolicy.name,
        'allowSkip': allowSkip,
        'requestedAt': requestedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory LearningActivityExecutionRequest.fromJson(
          Map<String, dynamic> json) =>
      LearningActivityExecutionRequest(
        requestId: json['requestId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        plan: LearningContinuationPlan.fromJson(
            json['plan'] as Map<String, dynamic>),
        currentState: AuthoritativeLearnerState.fromJson(
            json['currentState'] as Map<String, dynamic>),
        corpus: (json['corpus'] as List<dynamic>? ?? const [])
            .map((e) => NormalizedQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        existingSessionSpec: json['existingSessionSpec'] != null
            ? AdaptivePracticeSessionSpec.fromJson(
                json['existingSessionSpec'] as Map<String, dynamic>)
            : null,
        activeCheckpoint: json['activeCheckpoint'] != null
            ? SessionCheckpoint.fromJson(
                json['activeCheckpoint'] as Map<String, dynamic>)
            : null,
        feedbackPolicy: PracticeFeedbackPolicy.values.firstWhere(
          (p) => p.name == json['feedbackPolicy'],
          orElse: () => PracticeFeedbackPolicy.immediate,
        ),
        allowSkip: json['allowSkip'] as bool? ?? true,
        requestedAt: DateTime.parse(json['requestedAt'] as String).toUtc(),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningActivityExecutionRequest &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          plan.planId == other.plan.planId;

  @override
  int get hashCode => Object.hash(requestId, learnerId, examId, plan.planId);

  @override
  String toString() =>
      'LearningActivityExecutionRequest($requestId, plan=${plan.planId}, act=${plan.decision.type.name})';
}
