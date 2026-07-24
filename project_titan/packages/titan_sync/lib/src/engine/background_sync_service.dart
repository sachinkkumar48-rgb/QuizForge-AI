import 'dart:async';

import 'sync_manager.dart';

/// Background service for scheduling periodic and event-driven cloud synchronization.
class BackgroundSyncService {
  final SyncManager _syncManager;
  final Duration interval;

  Timer? _timer;
  bool _isRunning = false;

  BackgroundSyncService({
    required SyncManager syncManager,
    this.interval = const Duration(minutes: 15),
  }) : _syncManager = syncManager;

  /// Returns true if periodic sync is actively scheduled.
  bool get isRunning => _isRunning;

  /// Starts periodic background sync scheduling.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      await _syncManager.syncNow();
    });
  }

  /// Stops background sync scheduling.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Immediately triggers a background sync run.
  Future<void> triggerNow() async {
    await _syncManager.syncNow();
  }
}
