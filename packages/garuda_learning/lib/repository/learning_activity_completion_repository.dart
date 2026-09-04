/// Learning Activity Completion Repository (TITAN-KO-043.0 P43).
///
/// Encapsulates the persistence contract and in-memory implementation for storing
/// and querying completed learning activity records and enforcing activity-level idempotency.
library;

import 'dart:async';
import 'package:meta/meta.dart';

import '../domain/entities/learning_activity_outcome.dart';

/// Persisted record of a finalized learning activity.
@immutable
class LearningActivityCompletionRecord {
  /// Unique idempotency key identifying this activity completion.
  final String idempotencyKey;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Unique identifier of the completed activity.
  final String activityId;

  /// Underlying practice session identifier, if session-backed.
  final String? sessionId;

  /// Triggering continuation plan identifier.
  final String planId;

  /// Authoritative revision of the continuation plan at formulation time.
  final int planRevision;

  /// Normalized outcome resulting from the activity.
  final LearningActivityOutcome outcome;

  /// UTC timestamp when activity completion was persisted.
  final DateTime completedAt;

  /// Verification fingerprint matching the outcome.
  final String fingerprint;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  LearningActivityCompletionRecord({
    required String idempotencyKey,
    required String learnerId,
    required String examId,
    required String activityId,
    this.sessionId,
    required String planId,
    required this.planRevision,
    required this.outcome,
    DateTime? completedAt,
    String? fingerprint,
    Map<String, dynamic>? metadata,
  })  : idempotencyKey = idempotencyKey.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        activityId = activityId.trim(),
        planId = planId.trim(),
        completedAt = (completedAt ?? DateTime.now()).toUtc(),
        fingerprint = fingerprint ?? outcome.fingerprint,
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (this.idempotencyKey.isEmpty) {
      throw ArgumentError(
          'idempotencyKey cannot be empty for LearningActivityCompletionRecord');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for LearningActivityCompletionRecord');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for LearningActivityCompletionRecord');
    }
    if (this.activityId.isEmpty) {
      throw ArgumentError(
          'activityId cannot be empty for LearningActivityCompletionRecord');
    }
    if (this.planId.isEmpty) {
      throw ArgumentError(
          'planId cannot be empty for LearningActivityCompletionRecord');
    }
  }

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'learnerId': learnerId,
        'examId': examId,
        'activityId': activityId,
        if (sessionId != null) 'sessionId': sessionId,
        'planId': planId,
        'planRevision': planRevision,
        'outcome': outcome.toJson(),
        'completedAt': completedAt.toIso8601String(),
        'fingerprint': fingerprint,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory LearningActivityCompletionRecord.fromJson(
          Map<String, dynamic> json) =>
      LearningActivityCompletionRecord(
        idempotencyKey: json['idempotencyKey'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        activityId: json['activityId'] as String? ?? '',
        sessionId: json['sessionId'] as String?,
        planId: json['planId'] as String? ?? '',
        planRevision: (json['planRevision'] as num?)?.toInt() ?? 0,
        outcome: LearningActivityOutcome.fromJson(
            json['outcome'] as Map<String, dynamic>),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
        fingerprint: json['fingerprint'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'LearningActivityCompletionRecord($idempotencyKey, activity=$activityId, learner=$learnerId)';
}

/// Abstract contract for storing and querying learning activity completion records.
abstract class LearningActivityCompletionRepository {
  /// Persists a completion record atomically.
  Future<void> saveCompletionRecord(LearningActivityCompletionRecord record);

  /// Finds a completion record by its deterministic idempotency key.
  Future<LearningActivityCompletionRecord?> findByIdempotencyKey(
      String idempotencyKey);

  /// Finds a completion record by activity identifier within a tenant scope.
  Future<LearningActivityCompletionRecord?> findByActivityId({
    required String learnerId,
    required String examId,
    required String activityId,
  });

  /// Lists all completed activity records for a learner and exam.
  Future<List<LearningActivityCompletionRecord>> getCompletedActivities({
    required String learnerId,
    required String examId,
  });

  /// Clears all stored records (useful for test resets).
  Future<void> clear();
}

/// In-memory implementation of [LearningActivityCompletionRepository] for offline use and testing.
class InMemoryLearningActivityCompletionRepository
    implements LearningActivityCompletionRepository {
  final Map<String, LearningActivityCompletionRecord> _byKey = {};

  InMemoryLearningActivityCompletionRepository();

  @override
  Future<void> saveCompletionRecord(
      LearningActivityCompletionRecord record) async {
    _byKey[record.idempotencyKey] = record;
  }

  @override
  Future<LearningActivityCompletionRecord?> findByIdempotencyKey(
      String idempotencyKey) async {
    return _byKey[idempotencyKey];
  }

  @override
  Future<LearningActivityCompletionRecord?> findByActivityId({
    required String learnerId,
    required String examId,
    required String activityId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final cleanActivity = activityId.trim();

    for (final record in _byKey.values) {
      if (record.learnerId == cleanLearner &&
          record.examId == cleanExam &&
          record.activityId == cleanActivity) {
        return record;
      }
    }
    return null;
  }

  @override
  Future<List<LearningActivityCompletionRecord>> getCompletedActivities({
    required String learnerId,
    required String examId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    return _byKey.values
        .where((r) => r.learnerId == cleanLearner && r.examId == cleanExam)
        .toList();
  }

  @override
  Future<void> clear() async {
    _byKey.clear();
  }
}
