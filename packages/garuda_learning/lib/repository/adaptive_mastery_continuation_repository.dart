/// Adaptive Mastery Continuation Repository Contract (TITAN-KO-044.0 P44).
///
/// Interface defining persistent storage, multi-tenant querying, and idempotency
/// resolution for [AdaptiveContinuationFeedback] records.
library;

import '../domain/entities/adaptive_continuation_feedback.dart';

abstract class AdaptiveMasteryContinuationRepository {
  /// Persists an [AdaptiveContinuationFeedback] record.
  Future<void> saveFeedback(AdaptiveContinuationFeedback feedback);

  /// Resolves an existing feedback record by its unique idempotency key.
  Future<AdaptiveContinuationFeedback?> findByIdempotencyKey(
      String idempotencyKey);

  /// Resolves an existing feedback record by its feedbackId.
  Future<AdaptiveContinuationFeedback?> findById(String feedbackId);

  /// Retrieves all feedback records for a specific learner and exam, ordered by evaluation time.
  Future<List<AdaptiveContinuationFeedback>> findByLearnerAndExam({
    required String learnerId,
    required String examId,
  });

  /// Retrieves the most recent feedback record for a specific learner and exam.
  Future<AdaptiveContinuationFeedback?> getLatestFeedback({
    required String learnerId,
    required String examId,
  });

  /// Clears stored feedback records (for testing and isolation).
  Future<void> clear();
}
