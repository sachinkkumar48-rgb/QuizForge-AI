/// Adaptive Mastery Continuation Request Envelope (TITAN-KO-044.0 P44).
///
/// Encapsulates the complete pedagogical and operational context required to evaluate
/// objective progression, diagnose weak spots, and derive the next learning action.
library;

import 'package:meta/meta.dart';

import 'authoritative_learner_state.dart';
import 'curriculum_framework.dart';
import 'learning_activity_completion_result.dart';
import 'remedial_lesson.dart';
import 'resumable_learning_session.dart';
import 'review_item.dart';
import 'session_checkpoint.dart';

@immutable
class AdaptiveMasteryContinuationRequest {
  /// Unique identifier of this request.
  final String requestId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier (e.g. 'upsc', 'bpsc').
  final String examId;

  /// The outcome result of a just-completed learning activity, if chaining from P43.
  final LearningActivityCompletionResult? completionResult;

  /// Authoritative learner state, if supplied directly.
  final AuthoritativeLearnerState? currentState;

  /// Optional curriculum framework structure for syllabus progression checks.
  final CurriculumFramework? curriculumFramework;

  /// Optional review items for spaced repetition scheduling.
  final List<ReviewItem>? reviewItems;

  /// Available remedial lessons for binding diagnosed weaknesses.
  final List<RemedialLesson>? availableRemedialLessons;

  /// Active session checkpoint if an interrupted session exists.
  final SessionCheckpoint? activeCheckpoint;

  /// Active resumable session, if available.
  final ResumableLearningSession? activeSession;

  /// UTC timestamp of evaluation.
  final DateTime evaluatedAt;

  /// Diagnostic options.
  final Map<String, dynamic> options;

  AdaptiveMasteryContinuationRequest({
    required String requestId,
    required String learnerId,
    required String examId,
    this.completionResult,
    this.currentState,
    this.curriculumFramework,
    this.reviewItems,
    this.availableRemedialLessons,
    this.activeCheckpoint,
    this.activeSession,
    DateTime? evaluatedAt,
    Map<String, dynamic>? options,
  })  : requestId = requestId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        evaluatedAt =
            (evaluatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
                .toUtc(),
        options = Map<String, dynamic>.unmodifiable(
            options ?? const <String, dynamic>{}) {
    if (this.requestId.isEmpty) {
      throw ArgumentError('requestId cannot be empty');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
  }

  /// Factory creating a request directly from a completed P43 activity result.
  factory AdaptiveMasteryContinuationRequest.fromCompletion({
    required String requestId,
    required LearningActivityCompletionResult completionResult,
    CurriculumFramework? curriculumFramework,
    List<ReviewItem>? reviewItems,
    List<RemedialLesson>? availableRemedialLessons,
    DateTime? evaluatedAt,
    Map<String, dynamic>? options,
  }) {
    final learnerId = completionResult.outcome?.learnerId ??
        completionResult.resultingAuthoritativeState?.learnerId ??
        '';
    final examId = completionResult.outcome?.examId ??
        completionResult.resultingAuthoritativeState?.examId ??
        '';

    return AdaptiveMasteryContinuationRequest(
      requestId: requestId,
      learnerId: learnerId,
      examId: examId,
      completionResult: completionResult,
      currentState: completionResult.resultingAuthoritativeState,
      curriculumFramework: curriculumFramework,
      reviewItems: reviewItems,
      availableRemedialLessons: availableRemedialLessons,
      evaluatedAt: evaluatedAt ?? completionResult.completedAt,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'learnerId': learnerId,
        'examId': examId,
        if (completionResult != null)
          'completionResult': completionResult!.toJson(),
        if (currentState != null) 'currentState': currentState!.toJson(),
        'evaluatedAt': evaluatedAt.toIso8601String(),
        if (options.isNotEmpty) 'options': options,
      };

  @override
  String toString() =>
      'AdaptiveMasteryContinuationRequest($requestId, learner: $learnerId, exam: $examId)';
}
