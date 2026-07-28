import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orchestrator/dashboard_orchestrator.dart';
import '../orchestrator/unified_dashboard_state.dart';

/// Provider for the singleton DashboardOrchestrator instance.
final dashboardOrchestratorProvider = Provider<DashboardOrchestrator>((ref) {
  final orchestrator = DashboardOrchestrator();
  ref.onDispose(() {
    orchestrator.dispose();
  });
  return orchestrator;
});

/// StateNotifier handling state transitions for the Unified Dashboard.
class DashboardStateNotifier extends StateNotifier<UnifiedDashboardState> {
  final DashboardOrchestrator _orchestrator;
  final String userId;
  final String userName;

  DashboardStateNotifier(
    this._orchestrator, {
    required this.userId,
    required this.userName,
  }) : super(UnifiedDashboardState.initial()) {
    _init();
  }

  void _init() {
    state = _orchestrator.currentState;
    _orchestrator.stateStream.listen((newState) {
      if (mounted) {
        state = newState;
      }
    });
    load();
  }

  /// Triggers asynchronous dashboard data load.
  Future<void> load({bool forceRefresh = false}) async {
    await _orchestrator.loadDashboard(
      userId: userId,
      userName: userName,
      forceRefresh: forceRefresh,
    );
  }

  /// Triggers pull-to-refresh data reload.
  Future<void> refresh() async {
    await _orchestrator.refreshDashboard(
      userId: userId,
      userName: userName,
    );
  }
}

/// Family provider yielding UnifiedDashboardState for a given userId and userName.
final dashboardStateNotifierProvider = StateNotifierProvider.family<
    DashboardStateNotifier,
    UnifiedDashboardState,
    ({String userId, String userName})>(
  (ref, args) {
    final orchestrator = ref.watch(dashboardOrchestratorProvider);
    return DashboardStateNotifier(
      orchestrator,
      userId: args.userId,
      userName: args.userName,
    );
  },
);

/// Provider exposing quick action navigation callback signature.
typedef QuickActionHandler = void Function(String actionRoute,
    {Map<String, dynamic>? arguments});

final quickActionHandlerProvider =
    StateProvider<QuickActionHandler?>((ref) => null);
