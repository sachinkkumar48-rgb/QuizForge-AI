import '../engine/dashboard_engine.dart';
import '../models/dashboard_snapshot.dart';

/// Clean Architecture Use Case for forcing a real-time dashboard refresh.
class RefreshDashboardUseCase {
  final DashboardEngine _engine;

  const RefreshDashboardUseCase(this._engine);

  /// Forces fresh metric aggregation for [userId].
  Future<DashboardSnapshot> execute({
    required String userId,
    required String userName,
  }) {
    return _engine.refresh(
      userId: userId,
      userName: userName,
    );
  }
}
