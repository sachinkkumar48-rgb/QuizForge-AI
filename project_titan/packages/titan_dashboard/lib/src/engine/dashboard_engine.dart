import 'dart:async';

import '../models/dashboard_snapshot.dart';
import '../models/learning_insights.dart';
import '../repository/dashboard_repository.dart';

/// Central Analytics Dashboard 2.0 orchestration engine coordinating snapshot retrieval,
/// cache invalidation, and insights generation.
class DashboardEngine {
  final DashboardRepository _repository;
  final StreamController<DashboardSnapshot> _snapshotStreamController =
      StreamController<DashboardSnapshot>.broadcast();

  DashboardEngine(this._repository);

  /// Stream emitting updated dashboard snapshots.
  Stream<DashboardSnapshot> get snapshotStream =>
      _snapshotStreamController.stream;

  /// Retrieves dashboard snapshot (cached or aggregated fresh).
  Future<DashboardSnapshot> getSnapshot({
    required String userId,
    required String userName,
    bool forceRefresh = false,
  }) async {
    final snapshot = await _repository.getSnapshot(
      userId: userId,
      userName: userName,
      forceRefresh: forceRefresh,
    );
    _snapshotStreamController.add(snapshot);
    return snapshot;
  }

  /// Forces a fresh aggregation and cache update.
  Future<DashboardSnapshot> refresh({
    required String userId,
    required String userName,
  }) async {
    return getSnapshot(userId: userId, userName: userName, forceRefresh: true);
  }

  /// Generates target learning insights based on snapshot data.
  Future<LearningInsights> generateInsights({
    required String userId,
    required String userName,
  }) async {
    final snapshot = await getSnapshot(userId: userId, userName: userName);
    return snapshot.insights;
  }

  /// Clean up resources on disposal.
  Future<void> dispose() async {
    await _snapshotStreamController.close();
  }
}
