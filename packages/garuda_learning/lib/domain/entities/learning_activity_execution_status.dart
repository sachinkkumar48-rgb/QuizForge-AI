/// Learning Activity Execution Status & Error Models (TITAN-KO-042.0 P42).
///
/// Encapsulates categorical lifecycle statuses, strongly typed failure codes,
/// machine-readable error models, and exceptions for adaptive plan execution.
library;

import 'package:meta/meta.dart';

/// Categorical operational outcome of executing a [LearningContinuationPlan].
enum LearningActivityExecutionStatus {
  /// New learning activity or practice session successfully initialized and started.
  success,

  /// Active or interrupted practice session successfully resumed at checkpoint cursor.
  resumed,

  /// Curriculum fully completed; zero learning sessions required.
  completed,

  /// Execution rejected because plan was formulated against an obsolete state revision.
  stalePlan,

  /// Execution rejected because plan or request is malformed or invalid.
  invalidPlan,

  /// Execution rejected because specified learning target or objective is invalid or missing.
  invalidTarget,

  /// Execution rejected because requested activity type is unsupported by the executor.
  unsupportedActivity,

  /// Execution rejected because an unfinished session is already active for this context.
  sessionAlreadyActive,

  /// Resumption requested but session checkpoint is missing, corrupted, or incompatible.
  recoveryRequired,

  /// Downstream failure during question selection, session orchestration, or execution.
  executionFailed;

  /// Whether this execution status represents a successful pedagogical outcome.
  bool get isSuccess =>
      this == LearningActivityExecutionStatus.success ||
      this == LearningActivityExecutionStatus.resumed ||
      this == LearningActivityExecutionStatus.completed;

  /// Whether this execution status represents a terminal curriculum completion.
  bool get isTerminal => this == LearningActivityExecutionStatus.completed;

  /// Whether this execution status represents an operational or validation failure.
  bool get isFailure => !isSuccess;

  /// Human-readable display label.
  String get displayName => switch (this) {
        LearningActivityExecutionStatus.success => 'Activity Started',
        LearningActivityExecutionStatus.resumed => 'Session Resumed',
        LearningActivityExecutionStatus.completed => 'Curriculum Completed',
        LearningActivityExecutionStatus.stalePlan => 'Stale Plan Rejected',
        LearningActivityExecutionStatus.invalidPlan => 'Invalid Plan',
        LearningActivityExecutionStatus.invalidTarget => 'Invalid Target',
        LearningActivityExecutionStatus.unsupportedActivity =>
          'Unsupported Activity',
        LearningActivityExecutionStatus.sessionAlreadyActive =>
          'Session Already Active',
        LearningActivityExecutionStatus.recoveryRequired => 'Recovery Required',
        LearningActivityExecutionStatus.executionFailed => 'Execution Failed',
      };
}

/// Strongly typed machine-readable error code identifying execution failure causes.
enum PlanExecutionErrorCode {
  /// Authoritative learner state has advanced beyond the plan's revision.
  stalePlan,

  /// General request or plan structural validation failure.
  invalidPlan,

  /// Learner ID or exam ID mismatch across request, plan, and state.
  tenantMismatch,

  /// Target objective or session cursor coordinates are missing or invalid.
  invalidTarget,

  /// Activity type is unrecognized or unsupported.
  unsupportedActivity,

  /// Attempted to launch a new session while an active uncompleted session exists.
  sessionAlreadyActive,

  /// Resumption failed because checkpoint is absent or corrupted.
  recoveryRequired,

  /// Question corpus is empty when new question selection is required.
  corpusEmpty,

  /// Question selection failed to find eligible questions matching constraints.
  selectionFailed,

  /// Session orchestrator failed to produce a valid session specification.
  orchestrationFailed,

  /// Downstream execution coordinator or engine failure.
  downstreamExecutionFailed,

  /// Generic or unexpected execution error.
  unknown;

  /// Default associated status for this error code.
  LearningActivityExecutionStatus get defaultStatus => switch (this) {
        PlanExecutionErrorCode.stalePlan =>
          LearningActivityExecutionStatus.stalePlan,
        PlanExecutionErrorCode.invalidPlan ||
        PlanExecutionErrorCode.tenantMismatch =>
          LearningActivityExecutionStatus.invalidPlan,
        PlanExecutionErrorCode.invalidTarget =>
          LearningActivityExecutionStatus.invalidTarget,
        PlanExecutionErrorCode.unsupportedActivity =>
          LearningActivityExecutionStatus.unsupportedActivity,
        PlanExecutionErrorCode.sessionAlreadyActive =>
          LearningActivityExecutionStatus.sessionAlreadyActive,
        PlanExecutionErrorCode.recoveryRequired =>
          LearningActivityExecutionStatus.recoveryRequired,
        PlanExecutionErrorCode.corpusEmpty ||
        PlanExecutionErrorCode.selectionFailed ||
        PlanExecutionErrorCode.orchestrationFailed ||
        PlanExecutionErrorCode.downstreamExecutionFailed ||
        PlanExecutionErrorCode.unknown =>
          LearningActivityExecutionStatus.executionFailed,
      };
}

/// Machine-readable error descriptor attached to failed execution results.
@immutable
class PlanExecutionError {
  /// Error category code.
  final PlanExecutionErrorCode code;

  /// Diagnostic error description.
  final String message;

  /// Structured diagnostic metadata.
  final Map<String, dynamic> details;

  PlanExecutionError({
    required this.code,
    required String message,
    Map<String, dynamic>? details,
  })  : message = message.trim(),
        details = Map<String, dynamic>.unmodifiable(details ?? const {}) {
    if (this.message.isEmpty) {
      throw ArgumentError('message cannot be empty for PlanExecutionError');
    }
  }

  Map<String, dynamic> toJson() => {
        'code': code.name,
        'message': message,
        'details': details,
      };

  factory PlanExecutionError.fromJson(Map<String, dynamic> json) =>
      PlanExecutionError(
        code: PlanExecutionErrorCode.values.firstWhere(
          (c) => c.name == json['code'],
          orElse: () => PlanExecutionErrorCode.unknown,
        ),
        message: json['message'] as String? ?? 'Unknown error',
        details: json['details'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanExecutionError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'PlanExecutionError(${code.name}: $message)';
}

/// Strongly typed exception thrown on unrecoverable plan execution failures.
class PlanExecutionException implements Exception {
  final PlanExecutionErrorCode code;
  final String message;
  final Map<String, dynamic> details;

  const PlanExecutionException({
    required this.code,
    required this.message,
    this.details = const {},
  });

  /// Converts this exception into a serializable [PlanExecutionError].
  PlanExecutionError toError() => PlanExecutionError(
        code: code,
        message: message,
        details: details,
      );

  @override
  String toString() => 'PlanExecutionException(${code.name}): $message';
}
