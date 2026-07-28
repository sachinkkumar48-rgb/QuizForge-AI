import '../engine/dashboard_engine.dart';
import '../models/dashboard_snapshot.dart';

/// Clean Architecture Use Case for fetching current executive dashboard snapshot.
class GetDashboardSnapshotUseCase {
  final DashboardEngine _engine;

  const GetDashboardSnapshotUseCase(this._engine);

  /// Executes snapshot retrieval for [userId].
  Future<DashboardSnapshot> execute({
    required String userId,
    required String userName,
    bool forceRefresh = false,
  }) {
    return _engine.getSnapshot(
      userId: userId,
      userName: userName,
      forceRefresh: forceRefresh,
    );
  }
}
