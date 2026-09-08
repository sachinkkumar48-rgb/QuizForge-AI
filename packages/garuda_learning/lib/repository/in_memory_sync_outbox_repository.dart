/// In-Memory Sync Outbox Repository (TITAN-KO-047.0 P47).
///
/// Thread-safe in-memory implementation of SyncOutboxRepository providing
/// deterministic FIFO queuing and lifecycle status tracking.
library;

import '../domain/entities/sync_conflict.dart';
import '../domain/entities/sync_envelope.dart';
import '../domain/entities/sync_status.dart';
import 'sync_outbox_repository.dart';

/// In-memory implementation of [SyncOutboxRepository].
class InMemorySyncOutboxRepository implements SyncOutboxRepository {
  final Map<String, SyncEnvelope> _envelopes = {};
  final Map<String, SyncConflict> _conflicts = {};

  @override
  Future<void> enqueue(SyncEnvelope envelope) async {
    _envelopes[envelope.syncId] = envelope;
  }

  @override
  Future<List<SyncEnvelope>> peekPending(
      {String? learnerId, String? examId}) async {
    final cleanLearner = learnerId?.trim();
    final cleanExam = examId?.trim().toLowerCase();

    final pending = _envelopes.values.where((env) {
      if (cleanLearner != null && env.learnerId != cleanLearner) return false;
      if (cleanExam != null && env.examId != cleanExam) return false;
      return env.status == SyncStatus.pendingSync ||
          env.status == SyncStatus.failed;
    }).toList();

    // FIFO order by createdAt
    pending.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(pending);
  }

  @override
  Future<void> markSyncing(String syncId) async {
    final existing = _envelopes[syncId];
    if (existing != null) {
      _envelopes[syncId] = existing.copyWith(
        status: SyncStatus.syncing,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<void> markSynced(
    String syncId, {
    required int remoteRevision,
    required DateTime syncedAt,
  }) async {
    final existing = _envelopes[syncId];
    if (existing != null) {
      _envelopes[syncId] = existing.copyWith(
        status: SyncStatus.synced,
        revision: remoteRevision,
        updatedAt: syncedAt,
        errorMessage: null,
      );
    }
  }

  @override
  Future<void> markConflict(String syncId, SyncConflict conflict) async {
    final existing = _envelopes[syncId];
    if (existing != null) {
      _conflicts[syncId] = conflict;
      _envelopes[syncId] = existing.copyWith(
        status: SyncStatus.conflict,
        updatedAt: DateTime.now().toUtc(),
        errorMessage: 'Conflict: ${conflict.reason.name}',
      );
    }
  }

  @override
  Future<void> markFailed(String syncId, String errorMessage) async {
    final existing = _envelopes[syncId];
    if (existing != null) {
      _envelopes[syncId] = existing.copyWith(
        status: SyncStatus.failed,
        errorMessage: errorMessage,
        retryCount: existing.retryCount + 1,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<SyncEnvelope?> getBySyncId(String syncId) async {
    return _envelopes[syncId];
  }

  @override
  Future<List<SyncEnvelope>> getAll({String? learnerId, String? examId}) async {
    final cleanLearner = learnerId?.trim();
    final cleanExam = examId?.trim().toLowerCase();

    final results = _envelopes.values.where((env) {
      if (cleanLearner != null && env.learnerId != cleanLearner) return false;
      if (cleanExam != null && env.examId != cleanExam) return false;
      return true;
    }).toList();

    results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(results);
  }

  @override
  Future<int> clearCompleted() async {
    final completedKeys = _envelopes.entries
        .where((e) => e.value.status == SyncStatus.synced)
        .map((e) => e.key)
        .toList();

    for (final k in completedKeys) {
      _envelopes.remove(k);
      _conflicts.remove(k);
    }
    return completedKeys.length;
  }

  @override
  Future<void> clearAll() async {
    _envelopes.clear();
    _conflicts.clear();
  }

  /// Returns recorded conflict for a syncId, if any.
  SyncConflict? getConflict(String syncId) => _conflicts[syncId];
}
