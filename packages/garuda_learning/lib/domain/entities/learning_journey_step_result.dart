/// Learning Journey Step Result Domain Entity (TITAN-KO-041.0 P41).
///
/// Encapsulates the explicit, typed outcome of every production learning journey
/// operation (start, submit answer, skip, interrupt, resume, finalize).
library;

import 'package:meta/meta.dart';

import 'learning_journey_error.dart';
import 'learning_journey_session.dart';
import 'learning_journey_status.dart';
import 'practice_execution_state.dart';

/// Explicit operational result returned by journey orchestrator methods.
@immutable
class LearningJourneyStepResult {
  /// Whether the operation succeeded completely.
  final bool isSuccess;

  /// Lifecycle status following this operation.
  final LearningJourneyStatus status;

  /// Current immutable journey session aggregate, present on success.
  final LearningJourneySession? session;

  /// Direct result of the answer evaluation, if an answer was submitted in this step.
  final PracticeQuestionResult? lastAnswerResult;

  /// Descriptive diagnostic message.
  final String message;

  /// Typed error information, populated on failure.
  final LearningJourneyError? error;

  /// Timestamp when the operation concluded.
  final DateTime executedAt;

  const LearningJourneyStepResult({
    required this.isSuccess,
    required this.status,
    this.session,
    this.lastAnswerResult,
    required this.message,
    this.error,
    required this.executedAt,
  });

  /// Whether this result indicates a failure.
  bool get isFailure => !isSuccess;

  /// Constructs a successful step result.
  factory LearningJourneyStepResult.success({
    required LearningJourneySession session,
    PracticeQuestionResult? lastAnswerResult,
    String? message,
    DateTime? executedAt,
  }) {
    return LearningJourneyStepResult(
      isSuccess: true,
      status: session.status,
      session: session,
      lastAnswerResult: lastAnswerResult,
      message: message ?? 'Operation succeeded',
      executedAt: (executedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Constructs a failed step result.
  factory LearningJourneyStepResult.failure({
    required LearningJourneyErrorCode code,
    required String message,
    LearningJourneySession? session,
    DateTime? executedAt,
    Map<String, dynamic>? details,
    Object? cause,
  }) {
    return LearningJourneyStepResult(
      isSuccess: false,
      status: session?.status ?? LearningJourneyStatus.failed,
      session: session,
      message: message,
      error: LearningJourneyError(
        code: code,
        message: message,
        details: details ?? const {},
        cause: cause,
      ),
      executedAt: (executedAt ?? DateTime.now()).toUtc(),
    );
  }
}

/// Typed error descriptor for operational failure results.
@immutable
class LearningJourneyError {
  final LearningJourneyErrorCode code;
  final String message;
  final Map<String, dynamic> details;
  final Object? cause;

  const LearningJourneyError({
    required this.code,
    required this.message,
    this.details = const {},
    this.cause,
  });

  @override
  String toString() => 'LearningJourneyError(${code.name}): $message';
}
