import 'package:titan_storage/titan_storage.dart';

import '../engine/dashboard_cache.dart';
import '../engine/metrics_aggregator.dart';
import '../models/dashboard_snapshot.dart';
import '../models/learning_insights.dart';
import 'dashboard_repository.dart';

/// Concrete implementation of [DashboardRepository] providing offline-first caching and 10-engine aggregation.
class DashboardRepositoryImpl implements DashboardRepository {
  final MetricsAggregator _aggregator;
  final DashboardCache _cache;

  DashboardRepositoryImpl({
    MetricsAggregator? aggregator,
    StorageService? storageService,
    DashboardCache? cache,
  })  : _aggregator = aggregator ?? const MetricsAggregator(),
        _cache = cache ?? DashboardCache(storageService: storageService);

  @override
  Future<DashboardSnapshot> getSnapshot({
    required String userId,
    required String userName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedSnapshot(userId);
      if (cached != null) return cached;
    }

    final fresh = await _aggregator.aggregate(
      userId: userId,
      userName: userName,
    );
    await _cache.saveSnapshot(fresh);
    return fresh;
  }

  @override
  Future<void> saveSnapshot(DashboardSnapshot snapshot) async {
    await _cache.saveSnapshot(snapshot);
  }

  @override
  Future<LearningInsights> generateInsights({
    required String userId,
    required String userName,
  }) async {
    final snapshot = await getSnapshot(userId: userId, userName: userName);
    return snapshot.insights;
  }
}
