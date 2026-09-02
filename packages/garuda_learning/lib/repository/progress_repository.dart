/// Progress Repository (TITAN-KO-018.0 P18).
///
/// Interface and in-memory implementation for [LearnerProgress] storage.
library;

import '../domain/entities/learner_progress.dart';

abstract interface class ProgressRepository {
  /// Saves or updates a learner's progress record.
  void saveProgress(LearnerProgress progress);

  /// Saves or updates multiple progress records.
  void saveProgressBatch(List<LearnerProgress> progressList);

  /// Retrieves progress for a learner and objective pair, or null if not found.
  LearnerProgress? getProgress(String learnerId, String objectiveId);

  /// Retrieves all progress records for a specific learner.
  List<LearnerProgress> getProgressForLearner(String learnerId);

  /// Records that a practice session has been processed for a learner.
  void markSessionProcessed(String learnerId, String sessionId);

  /// Checks if a session has already been processed for a learner.
  bool isSessionProcessed(String learnerId, String sessionId);

  /// Retrieves all processed session IDs for a learner.
  Set<String> getProcessedSessionIds(String learnerId);

  /// Atomically applies a batch of learner progress updates and marks a session as processed.
  ///
  /// If any write fails, previous state is restored (rollback).
  void applyAtomicBatch({
    required String learnerId,
    required String sessionId,
    required List<LearnerProgress> progressList,
  });

  /// Retrieves all progress records in the system.
  List<LearnerProgress> getAll();

  /// Clears stored progress records (for testing).
  void clear();
}

class InMemoryProgressRepository implements ProgressRepository {
  final Map<String, LearnerProgress> _progressMap = {};
  final Map<String, Set<String>> _processedSessions = {};

  InMemoryProgressRepository();

  static String _key(String learnerId, String objectiveId) =>
      '$learnerId:$objectiveId';

  @override
  void saveProgress(LearnerProgress progress) {
    final key = _key(progress.learnerId, progress.objectiveId);
    _progressMap[key] = progress;
  }

  @override
  void saveProgressBatch(List<LearnerProgress> progressList) {
    for (final p in progressList) {
      saveProgress(p);
    }
  }

  @override
  LearnerProgress? getProgress(String learnerId, String objectiveId) {
    return _progressMap[_key(learnerId, objectiveId)];
  }

  @override
  List<LearnerProgress> getProgressForLearner(String learnerId) {
    final list = _progressMap.values
        .where((p) => p.learnerId == learnerId)
        .toList()
      ..sort((a, b) => a.objectiveId.compareTo(b.objectiveId));
    return List.unmodifiable(list);
  }

  @override
  void markSessionProcessed(String learnerId, String sessionId) {
    (_processedSessions[learnerId] ??= {}).add(sessionId.trim());
  }

  @override
  bool isSessionProcessed(String learnerId, String sessionId) {
    return _processedSessions[learnerId]?.contains(sessionId.trim()) ?? false;
  }

  @override
  Set<String> getProcessedSessionIds(String learnerId) {
    final set = _processedSessions[learnerId];
    return set == null ? const <String>{} : Set<String>.unmodifiable(set);
  }

  @override
  void applyAtomicBatch({
    required String learnerId,
    required String sessionId,
    required List<LearnerProgress> progressList,
  }) {
    // Snapshot prior state for rollback on failure
    final backupProgress = Map<String, LearnerProgress>.from(_progressMap);
    final backupSessions = {
      for (final e in _processedSessions.entries)
        e.key: Set<String>.from(e.value),
    };

    try {
      for (final p in progressList) {
        saveProgress(p);
      }
      markSessionProcessed(learnerId, sessionId);
    } catch (_) {
      // Rollback on any failure
      _progressMap
        ..clear()
        ..addAll(backupProgress);
      _processedSessions
        ..clear()
        ..addAll(backupSessions);
      rethrow;
    }
  }

  @override
  List<LearnerProgress> getAll() {
    final list = _progressMap.values.toList()
      ..sort((a, b) => _key(a.learnerId, a.objectiveId)
          .compareTo(_key(b.learnerId, b.objectiveId)));
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    _progressMap.clear();
    _processedSessions.clear();
  }
}
