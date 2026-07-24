import '../../models/question_statistics.dart';
import '../../repositories/statistics_repository.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_target.dart';

/// Sync target adapter for Question & Exam Statistics domain.
class StatisticsSyncTarget implements SyncTarget {
  final StatisticsRepository repository;
  final String deviceId;
  DateTime? _lastSyncTime;

  StatisticsSyncTarget({
    required this.repository,
    required this.deviceId,
  });

  @override
  SyncEntityType get targetType => SyncEntityType.statistics;

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> getPendingEntities(
      {DateTime? sinceTimestamp}) async {
    final stats = await repository.getAllStats();
    final List<SyncEntity<Map<String, dynamic>>> entities = [];

    for (final stat in stats) {
      final lastTime = stat.lastAttemptedAt ?? DateTime.now();
      if (sinceTimestamp != null && lastTime.isBefore(sinceTimestamp)) {
        continue;
      }
      final jsonMap = stat.toJson();
      final meta = SyncMetadata(
        entityId: stat.questionId,
        entityType: SyncEntityType.statistics,
        version: 1,
        updatedAt: lastTime.toUtc(),
        clientDeviceId: deviceId,
        checksum: SyncMetadata.computeChecksum(jsonMap),
      );
      entities.add(SyncEntity(metadata: meta, payload: jsonMap));
    }
    return entities;
  }

  @override
  Future<int> applyRemoteEntities(
      List<SyncEntity<Map<String, dynamic>>> entities) async {
    int appliedCount = 0;
    for (final entity in entities) {
      if (!entity.metadata.isDeleted) {
        final stat = QuestionStatistics.fromJson(entity.payload);
        await repository.updateQuestionStats(
          questionId: stat.questionId,
          isCorrect: stat.correctAttempts > 0,
          timeSpentSeconds: stat.averageTimeSeconds,
        );
      }
      appliedCount++;
    }
    return appliedCount;
  }

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> exportLocalEntities() async {
    return getPendingEntities();
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSyncTime;

  @override
  Future<void> updateLastSyncTime(DateTime timestamp) async {
    _lastSyncTime = timestamp;
  }
}
