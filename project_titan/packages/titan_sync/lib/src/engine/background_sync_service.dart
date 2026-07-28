import 'dart:async';

import '../models/sync_result.dart';
import 'sync_manager.dart';
import 'sync_orchestrator.dart';

/// Background worker scheduling startup, shutdown, periodic, network recovery,
/// and event-driven cloud synchronization for TITAN.
class BackgroundSyncService {
  final SyncManager? _syncManager;
  final SyncOrchestrator? _orchestrator;
  final Duration interval;

  Timer? _timer;
  bool _isRunning = false;

  BackgroundSyncService({
    SyncManager? syncManager,
    SyncOrchestrator? orchestrator,
    this.interval = const Duration(minutes: 15),
  })  : _syncManager = syncManager,
        _orchestrator = orchestrator;

  /// Returns true if periodic sync timer is active.
  bool get isRunning => _isRunning;

  /// Starts periodic background sync scheduling.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      await triggerNow();
    });
  }

  /// Stops background sync scheduling.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Triggers startup sync when app initializes.
  Future<SyncResult> onStartup() async {
    start();
    return await triggerNow();
  }

  /// Triggers shutdown sync before app closes or goes to background.
  Future<SyncResult> onShutdown() async {
    stop();
    return await triggerNow();
  }

  /// Triggers sync when network connectivity is restored.
  Future<SyncResult> onNetworkRestored() async {
    _orchestrator?.setOnlineStatus(true);
    return await triggerNow();
  }

  /// Immediately triggers a sync run.
  Future<SyncResult> triggerNow() async {
    if (_orchestrator != null) {
      return await _orchestrator.synchronize();
    } else if (_syncManager != null) {
      return await _syncManager.syncNow();
    }
    return SyncResult.empty();
  }
}
