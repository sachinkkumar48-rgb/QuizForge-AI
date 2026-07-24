import '../models/analytics_engine_models.dart';

/// Contract for persisting and retrieving historical analytics snapshots and daily counts.
abstract class AnalyticsRepository {
  /// Save a historical performance snapshot.
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot);

  /// Retrieve all historical snapshots ordered by timestamp.
  Future<List<AnalyticsSnapshot>> getSnapshots();

  /// Retrieve the latest historical snapshot.
  Future<AnalyticsSnapshot?> getLatestSnapshot();

  /// Delete a snapshot by its snapshotId.
  Future<void> deleteSnapshot(String snapshotId);

  /// Clear all stored analytics snapshots and history cache.
  Future<void> clear();
}
