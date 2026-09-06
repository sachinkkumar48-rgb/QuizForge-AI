/// In-Memory Adaptive Mastery Continuation Repository (TITAN-KO-044.0 P44).
///
/// Thread-safe in-memory store for [AdaptiveContinuationFeedback] providing
/// fast indexed lookup by idempotency key, feedbackId, and tenant coordinates.
library;

import 'dart:async';

import '../domain/entities/adaptive_continuation_feedback.dart';
import 'adaptive_mastery_continuation_repository.dart';

class InMemoryAdaptiveMasteryContinuationRepository
    implements AdaptiveMasteryContinuationRepository {
  final Map<String, AdaptiveContinuationFeedback> _byId = {};
  final Map<String, AdaptiveContinuationFeedback> _byIdempotencyKey = {};
  final Map<String, List<AdaptiveContinuationFeedback>> _byTenant = {};

  String _tenantKey(String learnerId, String examId) =>
      '${learnerId.trim()}:${examId.trim().toLowerCase()}';

  @override
  Future<void> saveFeedback(AdaptiveContinuationFeedback feedback) async {
    _byId[feedback.feedbackId] = feedback;
    _byIdempotencyKey[feedback.idempotencyKey] = feedback;

    final key = _tenantKey(feedback.learnerId, feedback.examId);
    final list = _byTenant.putIfAbsent(key, () => []);
    list.removeWhere((f) => f.feedbackId == feedback.feedbackId);
    list.add(feedback);
    list.sort((a, b) => a.evaluatedAt.compareTo(b.evaluatedAt));
  }

  @override
  Future<AdaptiveContinuationFeedback?> findByIdempotencyKey(
      String idempotencyKey) async {
    return _byIdempotencyKey[idempotencyKey];
  }

  @override
  Future<AdaptiveContinuationFeedback?> findById(String feedbackId) async {
    return _byId[feedbackId];
  }

  @override
  Future<List<AdaptiveContinuationFeedback>> findByLearnerAndExam({
    required String learnerId,
    required String examId,
  }) async {
    final key = _tenantKey(learnerId, examId);
    final list = _byTenant[key];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  @override
  Future<AdaptiveContinuationFeedback?> getLatestFeedback({
    required String learnerId,
    required String examId,
  }) async {
    final list =
        await findByLearnerAndExam(learnerId: learnerId, examId: examId);
    if (list.isEmpty) return null;
    return list.last;
  }

  @override
  Future<void> clear() async {
    _byId.clear();
    _byIdempotencyKey.clear();
    _byTenant.clear();
  }
}
