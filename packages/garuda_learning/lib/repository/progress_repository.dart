/// Progress Repository (TITAN-KO-018.0 P18).
///
/// Interface and in-memory implementation for [LearnerProgress] storage.
library;

import '../domain/entities/learner_progress.dart';

abstract interface class ProgressRepository {
  /// Saves or updates a learner's progress record.
  void saveProgress(LearnerProgress progress);

  /// Retrieves progress for a learner and objective pair, or null if not found.
  LearnerProgress? getProgress(String learnerId, String objectiveId);

  /// Retrieves all progress records for a specific learner.
  List<LearnerProgress> getProgressForLearner(String learnerId);

  /// Retrieves all progress records in the system.
  List<LearnerProgress> getAll();

  /// Clears stored progress records (for testing).
  void clear();
}

class InMemoryProgressRepository implements ProgressRepository {
  final Map<String, LearnerProgress> _progressMap = {};

  InMemoryProgressRepository();

  static String _key(String learnerId, String objectiveId) =>
      '$learnerId:$objectiveId';

  @override
  void saveProgress(LearnerProgress progress) {
    final key = _key(progress.learnerId, progress.objectiveId);
    _progressMap[key] = progress;
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
  List<LearnerProgress> getAll() {
    final list = _progressMap.values.toList()
      ..sort((a, b) => _key(a.learnerId, a.objectiveId)
          .compareTo(_key(b.learnerId, b.objectiveId)));
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    _progressMap.clear();
  }
}
