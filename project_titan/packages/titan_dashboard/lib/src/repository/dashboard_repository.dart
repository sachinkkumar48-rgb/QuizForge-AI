import '../models/dashboard_snapshot.dart';
import '../models/learning_insights.dart';

/// Abstract repository contract for retrieving and persisting executive dashboard snapshots.
abstract class DashboardRepository {
  /// Retrieves snapshot for [userId] (offline-first cached or fresh).
  Future<DashboardSnapshot> getSnapshot({
    required String userId,
    required String userName,
    bool forceRefresh = false,
  });

  /// Saves [snapshot] to offline storage.
  Future<void> saveSnapshot(DashboardSnapshot snapshot);

  /// Generates deep learning insights for [userId].
  Future<LearningInsights> generateInsights({
    required String userId,
    required String userName,
  });
}
